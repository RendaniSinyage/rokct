<?php

namespace App\Http\Controllers\API\v1\Dashboard\Payment;

use App\Helpers\ResponseError;
use App\Http\Controllers\Controller;
use App\Http\Requests\Payment\CardPaymentRequest;
use App\Models\Payment;
use App\Models\PaymentPayload;
use Illuminate\Support\Str;
use Exception;
use App\Models\Order;
use App\Models\SavedCard;
use App\Models\Transaction;
use App\Services\PaymentService\PayFastCardService;
use App\Traits\ApiResponse;
use App\Traits\OnResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Throwable;

class PayFastCardController extends Controller
{
    use OnResponse, ApiResponse;

    public function __construct(private PayFastCardService $service)
    {
        parent::__construct();
    }

    /**
     * Process direct card payment without WebView
     *
     * @param CardPaymentRequest $request
     * @return JsonResponse
     */
    public function directCardPayment(CardPaymentRequest $request): JsonResponse
{
    try {
        // Log the incoming request
        Log::info('Direct card payment request received', ['data' => $request->all()]);
        
        // Use the service to process the payment
        $result = $this->service->processDirectCardPayment($request->validated());
        
        return $this->successResponse('Direct card payment successful', [
            'transaction_id' => $result['transaction_id'] ?? null,
            'status' => $result['status'] ?? 'success'
        ]);
    } catch (Throwable $e) {
        $this->error($e);
        return $this->onErrorResponse([
            'code' => ResponseError::ERROR_400, 
            'message' => $e->getMessage()
        ]);
    }
}

    /**
     * Process payment using a saved card token
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function tokenPayment(Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'token' => 'required|string',
                'cart_id' => 'sometimes|exists:carts,id',
                'order_id' => 'sometimes|exists:orders,id',
                'parcel_id' => 'sometimes|exists:parcel_orders,id',
                'wallet_id' => 'sometimes|exists:wallets,id',
                'tips' => 'sometimes|numeric',
                'delivery_type' => 'sometimes|string',
                'currency_id' => 'sometimes|exists:currencies,id',
                'rate' => 'sometimes|numeric',
                'shop_id' => 'sometimes|exists:shops,id',
                'phone' => 'sometimes|string',
                'email' => 'sometimes|email',
                'address' => 'sometimes|array',
                'location' => 'sometimes|array',
                'username' => 'sometimes|string',
                'coupon' => 'sometimes|string',
                'delivery_date' => 'sometimes|string',
                'delivery_time' => 'sometimes|string',
                'type' => 'sometimes|string',
            ]);

            $result = $this->service->processTokenPayment($validated);
            
            return $this->successResponse('Token payment successful', [
                'transaction_id' => $result['transaction_id'] ?? null,
                'status' => $result['status'] ?? 'success'
            ]);
        } catch (Throwable $e) {
            $this->error($e);
            return $this->onErrorResponse([
                'code' => ResponseError::ERROR_400, 
                'message' => $e->getMessage()
            ]);
        }
    }

    /**
     * Tokenize a card for future use
     *
     * @param Request $request
     * @return JsonResponse
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
        
        // Save the card with all details
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
            'card_holder_name' => $cardHolder
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
     * Get saved cards for the authenticated user
     *
     * @return JsonResponse
     */
    public function getSavedCards(): JsonResponse
    {
        try {
            $userId = auth('sanctum')->id();
            
            if (!$userId) {
                return $this->onErrorResponse([
                    'code' => ResponseError::ERROR_401,
                    'message' => 'Unauthorized'
                ]);
            }

            $cards = $this->service->getSavedCards($userId);
            
            return $this->successResponse('Saved cards retrieved successfully', [
                'data' => $cards
            ]);
        } catch (Throwable $e) {
            $this->error($e);
            return $this->onErrorResponse([
                'code' => ResponseError::ERROR_400, 
                'message' => $e->getMessage()
            ]);
        }
    }

    /**
     * Delete a saved card
     *
     * @param string $id
     * @return JsonResponse
     */
    public function deleteCard(string $id): JsonResponse
    {
        try {
            $userId = auth('sanctum')->id();
            
            if (!$userId) {
                return $this->onErrorResponse([
                    'code' => ResponseError::ERROR_401,
                    'message' => 'Unauthorized'
                ]);
            }

            $success = $this->service->deleteCard($id, $userId);
            
            if (!$success) {
                return $this->onErrorResponse([
                    'code' => ResponseError::ERROR_404,
                    'message' => 'Card not found or not authorized to delete'
                ]);
            }
            
            return $this->successResponse('Card deleted successfully');
        } catch (Throwable $e) {
            $this->error($e);
            return $this->onErrorResponse([
                'code' => ResponseError::ERROR_400, 
                'message' => $e->getMessage()
            ]);
        }
    }

  /**
 * Fetch card details using a saved token
 * 
 * @param string $token
 * @return array|null
 */
public function fetchCardDetails(string $token): ?array
{
    try {
        // Get credentials from database
        $payment = Payment::where('tag', Payment::TAG_PAY_FAST)->first();
        
        if (!$payment) {
            Log::error('PayFast payment method not found in database');
            return null;
        }
        
        $paymentPayload = PaymentPayload::where('payment_id', $payment->id)->first();
        
        if (!$paymentPayload) {
            Log::error('PayFast payment payload not found in database');
            return null;
        }
        
        $payload = $paymentPayload->payload ?? [];
        
        // Build the API URL
        $baseUrl = ($payload['sandbox'] ?? true) 
            ? 'https://sandbox.payfast.co.za/api' 
            : 'https://api.payfast.co.za';
            
        $endpoint = "/subscriptions/$token/fetch";
        
        // Prepare headers with authentication
        $timestamp = gmdate('Y-m-d\TH:i:s');
        $merchantId = $payload['merchant_id'] ?? '';
        $passphrase = $payload['pass_phrase'] ?? '';
        
        // Calculate signature for the API request
        $signatureData = [
            'merchant-id' => $merchantId,
            'version' => 'v1',
            'timestamp' => $timestamp
        ];
        
        ksort($signatureData);
        
        // Generate signature string
        $signatureString = http_build_query($signatureData);
        
        if (!empty($passphrase)) {
            $signatureString .= '&passphrase=' . urlencode($passphrase);
        }
        
        $signature = md5($signatureString);
        
        // Log API request details
        Log::info('Sending PayFast API request for card details', [
            'url' => "$baseUrl$endpoint",
            'token' => $token,
        ]);
        
        // Make API call to fetch token details - try without headers first for testing
        $response = \Illuminate\Support\Facades\Http::withHeaders([
            'merchant-id' => $merchantId,
            'version' => 'v1',
            'timestamp' => $timestamp,
            'signature' => $signature
        ])->get("$baseUrl$endpoint");
        
        // Log response for debugging
        Log::info('PayFast API response for card details', [
            'status' => $response->status(),
            'body' => $response->body(),
        ]);
        
        if ($response->successful()) {
            $data = $response->json();
            
            // Extract card details from the response
            $responseData = $data['data']['response'] ?? null;
            
            if ($responseData) {
                // Try multiple possible field names for each card detail
                $lastFour = $responseData['card_last_digits'] ?? 
                           $responseData['last_four'] ?? 
                           $responseData['card_number'] ?? 
                           '••••';
                           
                $cardType = $responseData['card_brand'] ?? 
                           $responseData['card_type'] ?? 
                           $responseData['payment_method'] ?? 
                           'Card';
                           
                $expiryDate = $responseData['expiry_date'] ?? 
                             $responseData['card_expiry'] ?? 
                             'MM/YY';
                             
                $cardHolderName = $responseData['card_holder'] ?? 
                                 $responseData['card_holder_name'] ?? 
                                 '';
                
                return [
                    'token' => $token,
                    'last_four' => $lastFour,
                    'card_type' => $cardType,
                    'expiry_date' => $expiryDate,
                    'card_holder_name' => $cardHolderName
                ];
            }
        }
        
        // If the API call was not successful or we couldn't parse the response,
        // return default values rather than null
        return [
            'token' => $token,
            'last_four' => '••••',
            'card_type' => 'Card',
            'expiry_date' => 'MM/YY',
            'card_holder_name' => '',
        ];
    } catch (\Exception $e) {
        Log::error('Error fetching card details from PayFast API', [
            'error' => $e->getMessage(),
            'trace' => $e->getTraceAsString(),
            'token' => $token
        ]);
        
        // Return default values rather than null
        return [
            'token' => $token,
            'last_four' => '••••',
            'card_type' => 'Card',
            'expiry_date' => 'MM/YY',
            'card_holder_name' => '',
        ];
    }
}

  
    /**
 * Capture card token when returned from PayFast
 *
 * @param Request $request
 * @return JsonResponse
 */
public function captureToken(Request $request): JsonResponse
{
    try {
        // Extract parameters from request
        $token = $request->input('token');
        $payment_id = $request->input('payment_id');
        
        // Try both payment_id and payment ID from query param
        if (empty($payment_id)) {
            $payment_id = $request->query('payment_id');
        }
        
        Log::info('Token capture request received', [
            'token' => $token,
            'payment_id' => $payment_id,
            'all_params' => $request->all()
        ]);
        
        // First try to locate by ID
        $paymentProcess = \App\Models\PaymentProcess::find($payment_id);
        
        // If not found by ID, try data fields
        if (!$paymentProcess) {
            Log::info('Payment process not found by ID, trying alternative lookups', [
                'payment_id' => $payment_id
            ]);
            
            $paymentProcess = \App\Models\PaymentProcess::where('data->uuid', $payment_id)
                ->orWhere('data->m_payment_id', $payment_id)
                ->first();
        }
        
        if (!$paymentProcess) {
            throw new \Exception('Payment process not found. ID: ' . $payment_id);
        }
        
        $userId = $paymentProcess->user_id;
        
        if (!$userId) {
            throw new \Exception('User ID not found in payment process');
        }
        
        // If no token was provided, the process probably failed or was canceled
        if (empty($token)) {
            Log::warning('Token capture requested with no token value', [
                'payment_process_id' => $paymentProcess->id
            ]);
            
            return $this->successResponse('Token capture process incomplete', [
                'success' => false,
                'message' => 'No token provided'
            ]);
        }
        
        // Fetch card details using the token
        $cardDetails = $this->fetchCardDetails($token);
        
        // If we can't fetch details, use default values
        if (!$cardDetails) {
            $cardDetails = [
                'token' => $token,
                'last_four' => '••••',
                'card_type' => 'Card',
                'expiry_date' => '',
                'card_holder_name' => '',
            ];
        }
        
        // Create a unique ID for the saved card
        $savedCardId = Str::uuid()->toString();
        
        // Save the card with all details
        \App\Models\SavedCard::create([
            'id' => $savedCardId,
            'user_id' => $userId,
            'token' => $token,
            'last_four' => $cardDetails['last_four'],
            'card_type' => $cardDetails['card_type'],
            'expiry_date' => $cardDetails['expiry_date'],
            'card_holder_name' => $cardDetails['card_holder_name'],
        ]);
        
        Log::info('Card token successfully saved', [
            'token' => $token,
            'user_id' => $userId,
            'saved_card_id' => $savedCardId
        ]);
        
        return $this->successResponse('Card saved successfully', [
            'success' => true,
            'card_id' => $savedCardId
        ]);
    } catch (\Throwable $e) {
        Log::error('Failed to capture token', [
            'error' => $e->getMessage(),
            'trace' => $e->getTraceAsString(),
        ]);
        
        return $this->errorResponse($e->getMessage());
    }
}


public function testTokenInfo(Request $request): JsonResponse
{
    try {
        $token = $request->input('token');
        if (empty($token)) {
            return $this->errorResponse('Token is required');
        }

        $payment = Payment::where('tag', Payment::TAG_PAY_FAST)->first();
        if (!$payment) {
            return $this->errorResponse('PayFast payment method not found in database');
        }

        $paymentPayload = PaymentPayload::where('payment_id', $payment->id)->first();
        if (!$paymentPayload) {
            return $this->errorResponse('PayFast payment payload not found in database');
        }

        $payload = $paymentPayload->payload ?? [];
        $isProduction = !($payload['sandbox'] ?? false);

        Log::info('PayFast token test request details', [
            'environment' => $isProduction ? 'production' : 'sandbox',
            'token' => $token,
            'merchant_id' => $payload['merchant_id'] ?? 'not set',
            'merchant_key_exists' => isset($payload['merchant_key']),
            'passphrase_exists' => isset($payload['pass_phrase'])
        ]);

        $baseUrl = 'https://api.payfast.co.za';
        $endpoint = "/subscriptions/$token/fetch";
        $fullUrl = "$baseUrl$endpoint";

        $timestamp = gmdate('Y-m-d\TH:i:s');
        $merchantId = $payload['merchant_id'] ?? '';
        $passphrase = $payload['pass_phrase'] ?? '';

        // Correct Signature Calculation
        $signatureData = [
            'merchant-id' => $merchantId,
            'version' => 'v1',
            'timestamp' => $timestamp
        ];
        ksort($signatureData);
        $signatureString = http_build_query($signatureData);

        if (!empty($passphrase)) {
            $signatureString .= '&passphrase=' . $passphrase;
        }

        $signature = md5($signatureString);

        $headers = [
            'X-Merchant-Id' => $merchantId, 
            'X-Version' => 'v1',
            'X-Timestamp' => $timestamp,
            'X-Signature' => $signature
        ];

        Log::info('PayFast API request details', [
            'url' => $fullUrl,
            'method' => 'GET',
            'headers' => $headers
        ]);

        $response = \Illuminate\Support\Facades\Http::withHeaders($headers)->get($fullUrl);

        Log::info('PayFast API response', [
            'status' => $response->status(),
            'body' => $response->body()
        ]);

        $results = [
            'token' => $token,
            'environment' => $isProduction ? 'production' : 'sandbox',
            'request' => [
                'url' => $fullUrl,
                'method' => 'GET',
                'headers' => $headers
            ],
            'response' => [
                'success' => $response->successful(),
                'status_code' => $response->status(),
                'body' => $response->body(),
                'json' => null,
                'last_four' => null,
                'expiry_date' => null,
                'card_brand' => null,
                'payfast_message' => null,
            ]
        ];

        if ($response->successful()) {
            $responseData = json_decode($response->body(), true);
            if (json_last_error() === JSON_ERROR_NONE) {
                $results['response']['json'] = $responseData;
                $results['response']['last_four'] = $responseData['data']['response']['last_four'] ?? null;
                $results['response']['expiry_date'] = $responseData['data']['response']['expiry_date'] ?? null;
                $results['response']['card_brand'] = $responseData['data']['response']['card_brand'] ?? null;
                $results['response']['payfast_message'] = $responseData['data']['response']['message'] ?? null;
            } else {
                Log::error('Payfast response is not valid JSON');
                $results['response']['payfast_message'] = 'Payfast response is not valid JSON';
            }
        } else {
            $responseData = json_decode($response->body(), true);
            if (json_last_error() === JSON_ERROR_NONE) {
                $results['response']['payfast_message'] = $responseData['data']['response'] ?? $response->body();
            } else {
                $results['response']['payfast_message'] = $response->body();
            }
        }

        return $this->successResponse('Token test with request details completed', $results);
    } catch (\Throwable $e) {
        Log::error('Error testing token', [
            'error' => $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ]);

        return $this->errorResponse('Error testing token: ' . $e->getMessage());
    }
}



/**
 * Test a token with a zero-amount transaction
 * Uses credentials from database
 * 
 * @param string $token
 * @return array
 */
private function testTokenTransaction(string $token): array
{
    try {
        $payment = Payment::where('tag', Payment::TAG_PAY_FAST)->first();
        
        if (!$payment) {
            return ['success' => false, 'error' => 'PayFast payment method not found'];
        }
        
        $paymentPayload = PaymentPayload::where('payment_id', $payment->id)->first();
        
        if (!$paymentPayload) {
            return ['success' => false, 'error' => 'PayFast payment payload not found'];
        }
        
        $payload = $paymentPayload->payload ?? [];
        
        // Build the API URL
        $baseUrl = ($payload['sandbox'] ?? true) 
            ? 'https://sandbox.payfast.co.za/api' 
            : 'https://api.payfast.co.za';
            
        $endpoint = "/subscriptions/$token/adhoc";
        
        // Prepare headers with authentication
        $timestamp = gmdate('Y-m-d\TH:i:s');
        $merchantId = $payload['merchant_id'] ?? '';
        $merchantKey = $payload['merchant_key'] ?? ''; 
        $passphrase = $payload['pass_phrase'] ?? '';
        
        // Create test transaction data
        $transactionData = [
            'amount' => 100, // 1.00 in cents - PayFast often requires at least some amount
            'item_name' => 'Card validation test',
            'item_description' => 'Testing saved card token validity'
        ];
        
        // Calculate signature for the API request
        $signatureData = [
            'merchant-id' => $merchantId,
            'version' => 'v1',
            'timestamp' => $timestamp
        ];
        
        // Add transaction data to signature calculation
        foreach ($transactionData as $key => $value) {
            $signatureData[$key] = $value;
        }
        
        ksort($signatureData);
        
        // Generate signature string
        $signatureString = '';
        foreach ($signatureData as $key => $value) {
            $signatureString .= $key . '=' . urlencode($value) . '&';
        }
        
        // Remove trailing & and add passphrase if present
        $signatureString = rtrim($signatureString, '&');
        if (!empty($passphrase)) {
            $signatureString .= '&passphrase=' . urlencode($passphrase);
        }
        
        $signature = md5($signatureString);
        
        // Log API request details (without sensitive data)
        Log::info('Sending test transaction to PayFast API', [
            'url' => "$baseUrl$endpoint",
            'method' => 'POST',
            'transaction_data' => $transactionData,
            'merchant_id' => substr($merchantId, 0, 4) . '****', // Show only first 4 chars
            'signature_method' => 'MD5',
            'timestamp' => $timestamp
        ]);
        
        // Make API call
        $response = \Illuminate\Support\Facades\Http::withHeaders([
            'merchant-id' => $merchantId,
            'version' => 'v1',
            'timestamp' => $timestamp,
            'signature' => $signature
        ])->post("$baseUrl$endpoint", $transactionData);
        
        // Log full raw response
        Log::info('PayFast test transaction raw response', [
            'status' => $response->status(),
            'body' => $response->body(),
            'headers' => $response->headers()
        ]);
        
        if ($response->successful()) {
            $data = $response->json();
            
            return [
                'success' => true,
                'response' => $data
            ];
        } else {
            return [
                'success' => false,
                'status' => $response->status(),
                'error' => $response->body()
            ];
        }
    } catch (\Exception $e) {
        Log::error('Error testing token transaction', [
            'error' => $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ]);
        
        return [
            'success' => false,
            'error' => $e->getMessage()
        ];
    }
}

}
