<?php

namespace App\Services;

use GuzzleHttp\Client;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class ERPGoIntegrationService
{
    private $erpgoBaseUrl;
    private $clientId;
    private $clientSecret;
    private $accessToken;

    public function __construct()
    {
        $this->erpgoBaseUrl = config('services.sling.base_url');
        $this->clientId = config('services.sling.client_id');
        $this->clientSecret = config('services.sling.client_secret');

// Add debug logging to verify config is loaded:
    \Log::info('ERPGo Service Config Loaded', [
        'base_url' => $this->erpgoBaseUrl,
        'client_id' => $this->clientId,
        'client_secret_set' => !empty($this->clientSecret)
    ]);
    }

    /**
     * Connect seller to Slingbolt with password confirmation
     */
    public function connectSellerWithPassword($seller, $foodymanPassword, $shopName = null)
    {
        // First validate Juvo password
        if (!Hash::check($foodymanPassword, $seller->password)) {
            return [
                'success' => false,
                'error' => 'invalid_password',
                'message' => 'Invalid password. Please enter your correct Juvo password.'
            ];
        }

        // Password is correct, proceed with Slingbolt integration
        return $this->processERPGoConnection($seller, $shopName);
    }

    /**
     * Process ERPGo connection (create or link account)
     */
    private function processERPGoConnection($seller, $shopName = null)
    {
        try {
            // Get access token for API calls
            $this->refreshAccessToken();

            // Check if Slingbolt account exists
            $userCheck = $this->checkERPGoUser($seller->email);

            if ($userCheck['exists']) {
                // Handle existing user
                if (isset($userCheck['error'])) {
                    return [
                        'success' => false,
                        'error' => $userCheck['error'],
                        'message' => $userCheck['message']
                    ];
                }

                if (!$userCheck['already_linked']) {
                    // Link existing account
                    $linkResult = $this->linkExistingAccount($seller);
                    if (!$linkResult['success']) {
                        return $linkResult;
                    }
                }

                return [
                    'success' => true,
                    'action' => 'linked_existing',
                    'message' => 'Successfully connected to your existing Slingbolt account!'
                ];
            } else {
                // Create new ERPGo account
                $createResult = $this->createERPGoAccount($seller, $shopName);

                if ($createResult['success']) {
                    return [
                        'success' => true,
                        'action' => 'created_new',
                        'erpgo_credentials' => [
                            'email' => $seller->email,
                            'password' => $createResult['generated_password'],
                            'login_url' => $this->erpgoBaseUrl . '/login'
                        ],
                        'message' => 'Created new Slingbolt business account and connected successfully!'
                    ];
                }

                return $createResult;
            }

        } catch (\Exception $e) {
            Log::error('Slingbolt connection failed: ' . $e->getMessage());
            return [
                'success' => false,
                'error' => 'connection_failed',
                'message' => 'Failed to connect to Slingbolt. Please try again later.'
            ];
        }
    }

    /**
     * Get or refresh access token for API calls
     */
    private function refreshAccessToken()
    {
        $client = new Client();

        try {
            $response = $client->post($this->erpgoBaseUrl . '/oauth/token', [
                'form_params' => [
                    'grant_type' => 'client_credentials',
                    'client_id' => $this->clientId,
                    'client_secret' => $this->clientSecret,
                  //  'scope' => 'external-integration'
                ],
                'headers' => [
                    'Accept' => 'application/json',
                    'Content-Type' => 'application/x-www-form-urlencoded'
                ]
            ]);

            $tokenData = json_decode($response->getBody(), true);
            $this->accessToken = $tokenData['access_token'];

            // Store token with expiration for reuse
            cache()->put(
                'erpgo_access_token',
                $this->accessToken,
                now()->addSeconds($tokenData['expires_in'] - 60) // Refresh 1 minute early
            );

            return true;

        } catch (\Exception $e) {
            Log::error('Failed to get Slingbolt access token: ' . $e->getMessage());
            throw new \Exception('Failed to authenticate with Slingbolt');
        }
    }

    /**
     * Get cached access token or refresh if needed
     */
    private function getAccessToken()
    {
        if (!$this->accessToken) {
            $this->accessToken = cache()->get('erpgo_access_token');

            if (!$this->accessToken) {
                $this->refreshAccessToken();
            }
        }

        return $this->accessToken;
    }

    /**
     * Check if user exists in Slingbolt
     */
    private function checkERPGoUser($email)
    {
        $client = new Client();

        try {
            $response = $client->get($this->erpgoBaseUrl . '/api/external/check-user', [
                'query' => ['email' => $email],
                'headers' => [
                    'Authorization' => 'Bearer ' . $this->getAccessToken(),
                    'Accept' => 'application/json',
                ]
            ]);

            return json_decode($response->getBody(), true);

        } catch (\Exception $e) {
            Log::error('Failed to check Slingbolt user: ' . $e->getMessage());
            return ['exists' => false];
        }
    }

    /**
     * Create new Slingbolt account
     */
    private function createERPGoAccount($seller, $shopName = null)
    {
        $client = new Client();

        // Generate secure password for Slingbolt account
        $erpgoPassword = $this->generateSecurePassword();

        try {

		// Use shop name from Flutter or fallback
        $restaurantName = $shopName ?: 
                         ($seller->shop?->translation?->title ?? 
                          explode('@', $seller->email)[0] . ' Restaurant');
        
        Log::info('Creating ERPGo account', [
            'seller_id' => $seller->id,
            'email' => $seller->email,
            'restaurant_name' => $restaurantName,
            'shop_name_from_flutter' => $shopName,
            'firstname' => $seller->firstname,
            'lastname' => $seller->lastname
        ]);

            $response = $client->post($this->erpgoBaseUrl . '/api/external/create-seller-company', [
                'json' => [
                    'email' => $seller->email,
                    'first_name' => $seller->first_name ?? null,
                    'last_name' => $seller->last_name ?? null,
                    'restaurant_name' => $restaurantName,
                    'external_id' => $seller->id,
                    'password' => $erpgoPassword,
                    'external_platform' => 'juvo'
                ],
                'headers' => [
                    'Authorization' => 'Bearer ' . $this->getAccessToken(),
                    'Accept' => 'application/json',
                ]
            ]);

            $result = json_decode($response->getBody(), true);

            if ($result['success']) {
                // Update seller record in Juvo
                $seller->update([
                    'erpgo_connected' => true,
                    'erpgo_user_id' => $result['user_id'],
                    'erpgo_connected_at' => now()
                ]);

                return [
                    'success' => true,
                    'user_id' => $result['user_id'],
                    'generated_password' => $erpgoPassword
                ];
            }

            return $result;

        } catch (\Exception $e) {
            Log::error('Failed to create Slingbolt account: ' . $e->getMessage());
            return [
                'success' => false,
                'error' => 'creation_failed',
                'message' => 'Failed to create Slingbolt account'
            ];
        }
    }

    /**
     * Link existing Slingbolt account
     */
    private function linkExistingAccount($seller)
    {
        $client = new Client();

        try {
            $response = $client->post($this->erpgoBaseUrl . '/api/external/link-seller', [
                'json' => [
                    'email' => $seller->email,
                    'external_id' => $seller->id,
                    'external_platform' => 'juvo'
                ],
                'headers' => [
                    'Authorization' => 'Bearer ' . $this->getAccessToken(),
                    'Accept' => 'application/json',
                ]
            ]);

            $result = json_decode($response->getBody(), true);

            if ($result['success']) {
                // Update seller record in Juvo
                $seller->update([
                    'erpgo_connected' => true,
                    'erpgo_user_id' => $result['user_id'],
                    'erpgo_connected_at' => now()
                ]);
            }

            return $result;

        } catch (\Exception $e) {
            Log::error('Failed to link Slingbolt account: ' . $e->getMessage());
            return [
                'success' => false,
                'error' => 'linking_failed',
                'message' => 'Failed to link Slingbolt account'
            ];
        }
    }

    /**
     * Generate secure password for Slingbolt accounts
     */
    private function generateSecurePassword()
    {
        // Generate a 12-character password with uppercase, lowercase, numbers, and symbols
        $uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        $lowercase = 'abcdefghijklmnopqrstuvwxyz';
        $numbers = '0123456789';
        $symbols = '!@#$%^&*';

        $password = '';
        $password .= $uppercase[rand(0, strlen($uppercase) - 1)];
        $password .= $lowercase[rand(0, strlen($lowercase) - 1)];
        $password .= $numbers[rand(0, strlen($numbers) - 1)];
        $password .= $symbols[rand(0, strlen($symbols) - 1)];

        // Fill the rest with random characters
        $allChars = $uppercase . $lowercase . $numbers . $symbols;
        for ($i = 4; $i < 12; $i++) {
            $password .= $allChars[rand(0, strlen($allChars) - 1)];
        }

        return str_shuffle($password);
    }

    /**
     * Disconnect seller from Slingbolt
     */
    public function disconnectSeller($seller)
    {
        if (!$seller->erpgo_connected) {
            return [
                'success' => false,
                'error' => 'not_connected',
                'message' => 'Not connected to ERPGo'
            ];
        }

        try {
            $this->refreshAccessToken();

            $client = new Client();
            $response = $client->post($this->erpgoBaseUrl . '/api/external/disconnect-user', [
                'json' => [
                    'external_id' => $seller->id,
                    'external_platform' => 'juvo'
                ],
                'headers' => [
                    'Authorization' => 'Bearer ' . $this->getAccessToken(),
                    'Accept' => 'application/json',
                ]
            ]);

            $result = json_decode($response->getBody(), true);

            if ($result['success']) {
                // Update seller record
                $seller->update([
                    'erpgo_connected' => false,
                    'erpgo_user_id' => null,
                    'erpgo_connected_at' => null
                ]);
            }

            return $result;

        } catch (\Exception $e) {
            Log::error('Failed to disconnect from Slingbolt: ' . $e->getMessage());
            return [
                'success' => false,
                'error' => 'disconnection_failed',
                'message' => 'Failed to disconnect from Slingbolt'
            ];
        }
    }
}

