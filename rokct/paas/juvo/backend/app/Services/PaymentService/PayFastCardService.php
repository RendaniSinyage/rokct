<?php

namespace App\Services\PaymentService;

use App\Models\SavedCard;
use App\Models\Payment;
use App\Models\PaymentPayload;
use App\Models\PaymentProcess;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Exception;
use App\Helpers\ResponseError;

/**
 * Service for handling PayFast card payments and tokenization
 */
class PayFastCardService extends BaseService
{
    /**
     * Process direct card payment without WebView
     * 
     * @param array $data
     * @return array
     * @throws Exception
     */
    public function processDirectCardPayment(array $data): array
    {
        $payment = Payment::where('tag', Payment::TAG_PAY_FAST)->first();
        
        if (!$payment) {
            throw new Exception('PayFast payment method not found');
        }
        
        $paymentPayload = PaymentPayload::where('payment_id', $payment->id)->first();
        $payload = $paymentPayload?->payload ?? [];
        
        // Extract card details
        $cardNumber = $data['card_number'] ?? null;
        $cardHolder = $data['card_holder'] ?? null;
        $expiryDate = $data['expiry_date'] ?? null;
        $cvc = $data['cvc'] ?? null;
        
        if (!$cardNumber || !$cardHolder || !$expiryDate || !$cvc) {
            throw new Exception('Card details are incomplete');
        }
        
        // Get the payment payload from parent service
        [$key, $before] = $this->getPayload($data, $payload);
        $modelId = data_get($before, 'model_id');
        $totalPrice = round((float)data_get($before, 'total_price'), 2);
        
        // Create payment identifier for tracking
        $uuid = Str::uuid();
        
        // Ensure the payload has sandbox setting
        $isSandbox = $payload['sandbox'] ?? true;
        
        // Use PayFast API for direct card payment
        // Since PayFast doesn't have a direct card API, we'll simulate this
        // In production, you'd need to use PayFast's API or integrate with a PCI-compliant service
        
        try {
            // Create the transaction - in PROGRESS state initially
            $transaction = Transaction::create([
                'price' => $totalPrice,
                'user_id' => auth('sanctum')->id(),
                'payment_sys_id' => $payment->id,
                'payment_trx_id' => $uuid,
                'note' => "Direct card payment for " . Str::replace('App\\Models\\', '', $before['model_type']) . " #{$modelId}",
                'perform_time' => now(),
                'status_description' => "Processing direct card payment",
                'status' => Transaction::STATUS_PROGRESS,
            ]);
            
            // Store if user wants to save the card
            $saveCard = isset($data['save_card']) && (bool)$data['save_card'];
            
            // Create PaymentProcess to track this payment
            PaymentProcess::create([
                'id' => $uuid,
                'user_id' => auth('sanctum')->id(),
                'model_id' => $modelId,
                'model_type' => data_get($before, 'model_type'),
                'data' => array_merge([
                    'price' => $totalPrice,
                    'payment_id' => $payment->id,
                    'sandbox' => $isSandbox,
                    'transaction_id' => $transaction->id,
                    'save_card' => $saveCard,
                    // Include masked card data for reference
                    'card_last_four' => substr($cardNumber, -4),
                    'card_expiry' => $expiryDate,
                ], $before),
            ]);
            
            // In a real implementation, you would make an API call to PayFast or use their SDK
            // Since PayFast doesn't offer a direct API for card payments without redirect,
            // this is a simulated example that would need to be replaced with actual integration
            
            // Simulate successful payment processing
            $this->afterHook($uuid, Transaction::STATUS_PAID);
            
            // If user requested to save the card and payment was successful
            if ($saveCard) {
                // Generate a mock token - in production this would come from PayFast
                $token = Str::uuid()->toString();
                
                // Save the card
                $this->saveCardToken(
                    auth('sanctum')->id(),
                    $token,
                    substr($cardNumber, -4),
                    $this->detectCardType($cardNumber),
                    $expiryDate,
                    $cardHolder
                );
            }
            
            return [
                'transaction_id' => $transaction->id,
                'status' => 'success',
            ];
            
        } catch (Exception $e) {
            Log::error('Direct card payment failed: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString(),
                'data' => array_merge($data, ['card_number' => '************' . substr($cardNumber, -4)])
            ]);
            
            // Update transaction to failed status
            if (isset($transaction)) {
                $transaction->update([
                    'status' => Transaction::STATUS_CANCELED,
                    'status_description' => "Payment failed: " . $e->getMessage()
                ]);
            }
            
            throw $e;
        }
    }
    
    /**
 * Process payment using a saved card token
 * 
 * @param array $data
 * @return array
 * @throws Exception
 */
    public function processTokenPayment(array $data): array
{
    $token = $data['token'] ?? null;
    
    if (!$token) {
        Log::error('Token payment failed: No token provided', [
            'data_keys' => array_keys($data)
        ]);
        throw new Exception('Token is required');
    }
    
    try {
        // Log the start of the process with comprehensive details
        Log::info('Starting PayFast token payment process', [
            'token' => $token,
            'data_keys' => array_keys($data),
            'user_id' => auth('sanctum')->id()
        ]);
        
        // Verify the token belongs to the current user
        $savedCard = SavedCard::where('token', $token)
            ->where('user_id', auth('sanctum')->id())
            ->first();
            
        if (!$savedCard) {
            Log::error('Token payment failed: Invalid or unauthorized token', [
                'token' => $token,
                'user_id' => auth('sanctum')->id()
            ]);
            throw new Exception('Invalid or unauthorized token');
        }
        
        $payment = Payment::where('tag', Payment::TAG_PAY_FAST)->first();
        
        if (!$payment) {
            Log::error('Token payment failed: PayFast payment method not found');
            throw new Exception('PayFast payment method not found');
        }
        
        $paymentPayload = PaymentPayload::where('payment_id', $payment->id)->first();
        $payload = $paymentPayload?->payload ?? [];
        
        // Validate payload configuration
        if (empty($payload['merchant_id']) || empty($payload['merchant_key'])) {
            Log::error('Token payment failed: Incomplete PayFast configuration', [
                'merchant_id_exists' => !empty($payload['merchant_id']),
                'merchant_key_exists' => !empty($payload['merchant_key'])
            ]);
            throw new Exception('PayFast configuration is incomplete');
        }
        
        // Get the payment data
        [$key, $before] = $this->getPayload($data, $payload);
        $modelId = data_get($before, 'model_id');
        $totalPrice = round((float)data_get($before, 'total_price'), 2);
        
        Log::info('Payment details prepared for token payment', [
            'model_type' => data_get($before, 'model_type'),
            'model_id' => $modelId,
            'total_price' => $totalPrice,
            'key' => $key
        ]);
        
        // Create payment identifier
        $uuid = Str::uuid();
        
        // Create the transaction - in PROGRESS state initially
        $transaction = Transaction::create([
            'price' => $totalPrice,
            'user_id' => auth('sanctum')->id(),
            'payment_sys_id' => $payment->id,
            'payment_trx_id' => $uuid,
            'note' => "Token payment for " . Str::replace('App\\Models\\', '', $before['model_type']) . " #{$modelId}",
            'perform_time' => now(),
            'status_description' => "Processing token payment",
            'status' => Transaction::STATUS_PROGRESS,
        ]);
        
        // Create PaymentProcess record
        PaymentProcess::create([
            'id' => $uuid,
            'user_id' => auth('sanctum')->id(),
            'model_id' => $modelId,
            'model_type' => data_get($before, 'model_type'),
            'data' => array_merge([
                'price' => $totalPrice,
                'payment_id' => $payment->id,
                'transaction_id' => $transaction->id,
                'token' => $token,
                'card_last_four' => $savedCard->last_four,
            ], $before),
        ]);
        
        // For debugging, we're skipping the actual API call and simulating success
        // Log this fact so it's clear what's happening
        Log::info('Token payment simulated success for MVP', [
            'token' => $token,
            'transaction_id' => $transaction->id
        ]);
        
        // Update the transaction and trigger afterHook
        Log::info('Token payment successful, processing afterHook', [
            'uuid' => $uuid,
            'transaction_id' => $transaction->id
        ]);
        
        $this->afterHook($uuid, Transaction::STATUS_PAID);
        
        return [
            'transaction_id' => $transaction->id,
            'status' => 'success',
            'message' => 'Payment processed successfully',
            'card_info' => [
                'last_four' => $savedCard->last_four,
                'card_type' => $savedCard->card_type
            ]
        ];
        
    } catch (Exception $e) {
        Log::error('Token payment process failed', [
            'error_message' => $e->getMessage(),
            'trace' => $e->getTraceAsString(),
            'token' => $token,
            'user_id' => auth('sanctum')->id()
        ]);
        
        // Ensure the transaction is marked as failed if it exists
        if (isset($transaction) && $transaction->status !== Transaction::STATUS_CANCELED) {
            $transaction->update([
                'status' => Transaction::STATUS_CANCELED,
                'status_description' => "Payment failed: " . $e->getMessage()
            ]);
        }
        
        throw $e;
    }
}

private function processPayFastTokenPayment(string $token, float $amount, array $payload, $modelId, string $modelType): array
{
    try {
        Log::info('Starting PayFast token payment process', [
            'token' => $token,
            'amount' => $amount,
            'model_id' => $modelId,
            'model_type' => $modelType,
            'payload' => $payload,
        ]);

        // Validate payload configuration
        if (empty($payload['merchant_id']) || empty($payload['merchant_key'])) {
            Log::error('PayFast configuration incomplete for token payment', [
                'merchant_id_exists' => !empty($payload['merchant_id']),
                'merchant_key_exists' => !empty($payload['merchant_key'])
            ]);
            return [
                'success' => false,
                'message' => 'PayFast configuration is incomplete'
            ];
        }

        // Detailed logging of payment environment
        $isSandbox = $payload['sandbox'] ?? true;
        $baseUrl = $isSandbox
            ? 'https://sandbox.payfast.co.za/api'
            : 'https://api.payfast.co.za';

        Log::info('PayFast token payment environment', [
            'base_url' => $baseUrl,
            'is_sandbox' => $isSandbox
        ]);

        // Format amount in cents (integer) as required by PayFast
        $amountInCents = (int)($amount * 100);

        // Create unique payment ID
        $paymentId = Str::uuid()->toString();

        // Build the API endpoint
        $endpoint = "/subscriptions/{$token}/adhoc";
        $fullUrl = "{$baseUrl}{$endpoint}";

        // Prepare request details
        $body = [
            'amount' => $amountInCents,
            'item_name' => "Payment for $modelType #$modelId",
            'm_payment_id' => $paymentId
        ];

        // Prepare signature calculation
        $params = array_merge($body, [
            'merchant-id' => $payload['merchant_id'],
            'version' => 'v1',
            'timestamp' => date('Y-m-d\TH:i:s')
        ]);

        ksort($params); // CRITICAL: This is where we sort the initial params

        // Signature calculation with extensive logging
        $signatureParams = $params;
        if (!empty($payload['pass_phrase'])) {
            $signatureParams['passphrase'] = $payload['pass_phrase']; // CRITICAL: Passphrase goes *after* initial sort
        }

        ksort($signatureParams); // CRITICAL: Sort again *after* adding the passphrase

        $signatureString = http_build_query($signatureParams);
        $signature = md5($signatureString);

        Log::info('PayFast signature details', [
            'signature_params' => array_keys($signatureParams),
            'signature_string_length' => strlen($signatureString),
            'signature_string' => $signatureString,
            'generated_signature' => $signature,
        ]);

        // Make the API request
        Log::info('PayFast token payment request details', [
            'full_url' => $fullUrl,
            'headers' => [
                'merchant-id' => $payload['merchant_id'],
                'version' => 'v1',
                'timestamp' => $params['timestamp'],
                'signature' => $signature
            ],
            'body' => $body,
        ]);

        $response = Http::withHeaders([
            'merchant-id' => $payload['merchant_id'],
            'version' => 'v1',
            'timestamp' => $params['timestamp'],
            'signature' => $signature
        ])->post($fullUrl, $body);

        // Log the full response for debugging
        Log::info('PayFast token payment API response', [
            'status' => $response->status(),
            'body' => $response->body()
        ]);

        // Process the response
        if ($response->successful()) {
            $data = $response->json();

            Log::info('Successful token payment', [
                'payment_id' => $data['data']['response']['pf_payment_id'] ?? null
            ]);

            return [
                'success' => true,
                'payment_id' => $data['data']['response']['pf_payment_id'] ?? null
            ];
        } else {
            // Detailed error logging
            $errorData = $response->json();
            $errorMessage = is_array($errorData) && isset($errorData['data']['response']) ?
                $errorData['data']['response'] : 'Unknown token payment error';

            Log::error('Token payment API call failed', [
                'error_message' => $errorMessage,
                'response_status' => $response->status(),
                'response_body' => $response->body()
            ]);

            return [
                'success' => false,
                'message' => $errorMessage
            ];
        }
    } catch (\Exception $e) {
        Log::error('Token payment processing exception', [
            'error_message' => $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ]);

        return [
            'success' => false,
            'message' => $e->getMessage()
        ];
    }
}
 
    
    /**
     * Tokenize a card for future use
     * 
     * @param array $data
     * @return array
     * @throws Exception
     */
    public function tokenizeCard(array $data): array
    {
        $cardNumber = $data['card_number'] ?? null;
        $cardHolder = $data['card_holder'] ?? null;
        $expiryDate = $data['expiry_date'] ?? null;
        $cvc = $data['cvc'] ?? null;
        
        if (!$cardNumber || !$cardHolder || !$expiryDate || !$cvc) {
            throw new Exception('Card details are incomplete');
        }
        
        try {
            // Generate a token - in a real implementation, this would be done via PayFast API
            // For example purposes, we'll generate a UUID
            $token = Str::uuid()->toString();
            
            // Detect card type based on number
            $cardType = $this->detectCardType($cardNumber);
            
            // Get last 4 digits
            $lastFour = substr($cardNumber, -4);
            
            // Save the card
            $savedCard = $this->saveCardToken(
                auth('sanctum')->id(),
                $token,
                $lastFour,
                $cardType,
                $expiryDate,
                $cardHolder
            );
            
            return [
                'token' => $token,
                'id' => $savedCard->id,
                'last_four' => $lastFour,
                'card_type' => $cardType,
                'expiry_date' => $expiryDate,
            ];
        } catch (Exception $e) {
            Log::error('Card tokenization failed: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString(),
                'user_id' => auth('sanctum')->id(),
            ]);
            
            throw $e;
        }
    }
    
    /**
     * Get all saved cards for a user
     * 
     * @param int $userId
     * @return array
     */
    public function getSavedCards(int $userId): array
    {
        $cards = SavedCard::where('user_id', $userId)->get();
        
        return $cards->toArray();
    }
    
    /**
 * Delete a saved card
 *
 * @param string $cardId
 * @param int $userId
 * @return bool
 * @throws Exception
 */
public function deleteCard(string $cardId, int $userId): bool
{
    try {
        $card = SavedCard::where('id', $cardId)
            ->where('user_id', $userId)
            ->first();
        
        if (!$card) {
            return false;
        }
        
        // Get PayFast payment configuration
        $payment = Payment::where('tag', Payment::TAG_PAY_FAST)->first();
        $paymentPayload = PaymentPayload::where('payment_id', $payment?->id)->first();
        $payload = $paymentPayload?->payload ?? [];
        
        // First, cancel the tokenization agreement with PayFast
        $this->cancelTokenAgreement($card->token, $payload);
        
        // Then delete the local record
        return $card->delete();
    } catch (Exception $e) {
        Log::error('PayFast card deletion error', [
            'error' => $e->getMessage(),
            'trace' => $e->getTraceAsString(),
            'card_id' => $cardId
        ]);
        
        // If PayFast API fails, still try to delete the local record
        $card = SavedCard::where('id', $cardId)
            ->where('user_id', $userId)
            ->first();
            
        if ($card) {
            return $card->delete();
        }
        
        return false;
    }
}

    /**
 * Cancel a tokenization agreement with PayFast
 *
 * @param string $token
 * @param array $payload
 * @return bool
 */
private function cancelTokenAgreement(string $token, array $payload): bool
{
    try {
        // Configure environment
        $isProduction = !($payload['sandbox'] ?? true);
        $baseUrl = $isProduction
            ? 'https://api.payfast.co.za'
            : 'https://sandbox.payfast.co.za/api';
            
        $endpoint = "/subscriptions/$token/cancel";
        $fullUrl = "$baseUrl$endpoint";
        
        // Get credentials
        $merchantId = $payload['merchant_id'];
        $merchantKey = $payload['merchant_key']; // Added merchant key
        $passPhrase = $payload['pass_phrase'] ?? '';
        
        // Format timestamp exactly as PayFast expects
        $timestamp = gmdate('Y-m-d\TH:i:s');
        
        // Prepare signature parameters
        $signatureParams = [
            'merchant-id' => $merchantId,
            'merchant-key' => $merchantKey, // Include merchant key
            'version' => 'v1',
            'timestamp' => $timestamp
        ];
        
        // Sort parameters alphabetically (CRITICAL for signature calculation)
        ksort($signatureParams);
        
        // Convert to string for signature
        $signatureString = '';
        foreach ($signatureParams as $key => $value) {
            $signatureString .= $key . '=' . urlencode($value) . '&';
        }
        $signatureString = rtrim($signatureString, '&');
        
        // Add passphrase if provided (AFTER initial sort)
        if (!empty($passPhrase)) {
            $signatureString .= '&passphrase=' . urlencode($passPhrase);
        }
        
        // Calculate MD5 hash of the signature string
        $signature = md5($signatureString);
        
        // Prepare headers
        $headers = [
            'merchant-id' => $merchantId,
            'merchant-key' => $merchantKey, // Include merchant key in headers
            'version' => 'v1',
            'timestamp' => $timestamp,
            'signature' => $signature,
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
        ];
        
        // Log the request details
        Log::info('PayFast cancel token request', [
            'url' => $fullUrl,
            'token' => $token,
            'merchant_id' => substr($merchantId, 0, 4) . '****'
        ]);
        
        // Make the API request
        $response = Http::withHeaders($headers)->put($fullUrl);
        
        // Log the response
        Log::info('PayFast API response', [
            'status' => $response->status(),
            'body' => $response->body()
        ]);
        
        // Check if request was successful
        if ($response->successful()) {
            Log::info('PayFast token cancelled successfully', [
                'token' => $token
            ]);
            return true;
        }
        
        // Check for specific error scenarios
        $responseData = $response->json() ?? [];
        $errorMessage = $responseData['data']['response'] ?? 'Unknown error';
        
        // Consider token already invalid/cancelled as a success
        if (strpos($errorMessage, 'not found') !== false || 
            strpos($errorMessage, 'does not exist') !== false) {
            Log::info('Token appears to be already canceled or invalid', [
                'token' => $token,
                'message' => $errorMessage
            ]);
            return true;
        }
        
        // Log specific error for failed cancellation
        Log::error('Failed to cancel PayFast token', [
            'token' => $token,
            'error' => $errorMessage,
            'status' => $response->status()
        ]);
        
        return false;
    } catch (Exception $e) {
        // Log any unexpected exceptions
        Log::error('Exception while canceling PayFast token', [
            'token' => $token,
            'error' => $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ]);
        
        return false;
    }
}    
    /**
     * Save card token to database
     * 
     * @param int $userId
     * @param string $token
     * @param string $lastFour
     * @param string $cardType
     * @param string $expiryDate
     * @param string $cardHolderName
     * @return SavedCard
     */
    private function saveCardToken(
        int $userId,
        string $token,
        string $lastFour,
        string $cardType,
        string $expiryDate,
        string $cardHolderName
    ): SavedCard {
        return SavedCard::create([
            'id' => Str::uuid()->toString(),
            'user_id' => $userId,
            'token' => $token,
            'last_four' => $lastFour,
            'card_type' => $cardType,
            'expiry_date' => $expiryDate,
            'card_holder_name' => $cardHolderName,
        ]);
    }
    
    /**
     * Detect card type based on card number
     * 
     * @param string $cardNumber
     * @return string
     */
    private function detectCardType(string $cardNumber): string
    {
        // Remove any spaces or dashes
        $number = preg_replace('/\D/', '', $cardNumber);
        
        // Check card type based on BIN range
        if (preg_match('/^4/', $number)) {
            return 'Visa';
        } elseif (preg_match('/^5[1-5]/', $number)) {
            return 'Mastercard';
        } elseif (preg_match('/^3[47]/', $number)) {
            return 'American Express';
        } elseif (preg_match('/^6(?:011|5)/', $number)) {
            return 'Discover';
        } else {
            return 'Card';
        }
    }
}
