<?php
 
namespace App\Http\Controllers\API\v1\Dashboard\Payment;

use App\Helpers\ResponseError;
use App\Http\Controllers\Controller;
use App\Http\Requests\Payment\SplitRequest;
use App\Http\Requests\Payment\StripeRequest;
use App\Http\Requests\Shop\SubscriptionRequest;
use App\Models\Currency;
use App\Models\Transaction;
use App\Services\PaymentService\PayFastService;
use App\Traits\ApiResponse;
use App\Traits\OnResponse;
use Illuminate\Http\Client\Response;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Throwable;

class PayFastController extends Controller
{
	use OnResponse, ApiResponse;

	public function __construct(private PayFastService $service)
	{
		parent::__construct();
	}

	 /**
     * @param array $data
     * @return PaymentProcess|array
     * @throws Exception
     */
    /**
 * Process transaction.
 *
 * @param Request $request
 * @return JsonResponse
 */
public function orderProcessTransaction(Request $request): JsonResponse
{
    try {
        // Extract the data from the request
        $data = $request->all();
        
        // Ensure we have a unique ID for this transaction
        if (!isset($data['payment_id'])) {
            $data['payment_id'] = (string) Str::uuid();
        }
        
        // Call the service method with the data
        $result = $this->service->orderProcessTransaction($data);
        
        // If it's a mobile request, return the appropriate response
        if (isset($data['type']) && $data['type'] === 'mobile') {
            return $this->successResponse('success', $result);
        }
        
        // Otherwise, return the standard response
        return $this->successResponse('success', $result);
    } catch (Throwable $e) {
        $this->error($e);
        return $this->onErrorResponse([
            'message' => $e->getMessage(),
            'code' => ResponseError::ERROR_501
        ]);
    }
}

    

	/**
	 * process transaction.
	 *
	 * @param SplitRequest $request
	 * @return JsonResponse
	 */
	public function splitTransaction(SplitRequest $request): JsonResponse
	{
		try {
			$result = $this->service->splitTransaction($request->all());
			$result->id = (string)$result->id;

			return $this->successResponse('success', $result);
		} catch (Throwable $e) {
			$this->error($e);
			return $this->onErrorResponse([
				'message' => $e->getMessage(),
				'param'   => $e->getFile() . $e->getLine()
			]);
		}
	}

	/**
	 * process transaction.
	 *
	 * @param SubscriptionRequest $request
	 * @return JsonResponse
	 */
	public function subscriptionProcessTransaction(SubscriptionRequest $request): JsonResponse
	{
		$shop = auth('sanctum')->user()?->shop ?? auth('sanctum')->user()?->moderatorShop;

		$currency = Currency::currenciesList()->where('active', 1)->where('default', 1)->first()?->title;

		if (empty($shop)) {
			return $this->onErrorResponse([
				'message' => __('errors.' . ResponseError::SHOP_NOT_FOUND, locale: $this->language)
			]);
		}

		if (empty($currency)) {
			return $this->onErrorResponse([
				'message' => __('errors.' . ResponseError::CURRENCY_NOT_FOUND, locale: $this->language)
			]);
		}

		try {
			$result = $this->service->subscriptionProcessTransaction($request->all(), $shop);

			return $this->successResponse('success', $result);
		} catch (Throwable $e) {
			$this->error($e);
			return $this->onErrorResponse([
				'message' => __('errors.' . ResponseError::ERROR_501, locale: $this->language)
			]);
		}
	}

	/**
 * Handle PayFast payment webhook optimized for production environment
 *
 * @param Request $request
 * @return void
 */
/**
 * Handle PayFast payment webhook 
 * 
 * This method prioritizes order creation by first processing the payment status
 * and only then handling any token-related operations.
 *
 * @param Request $request
 * @return void
 */
public function paymentWebHook(Request $request): void
{
    Log::info('PayFast Webhook Request:', $request->all());
    
    // Check for payment_id from query parameters first as this is explicitly set in notify URL
    $payment_id = $request->query('payment_id');
    
    // If not in query params, try from POST data in multiple possible fields
    if (!$payment_id) {
        $payment_id = $request->input('payment_id') ?? 
                     $request->input('m_payment_id') ?? 
                     $request->input('pf_payment_id');
    }
    
    if (!$payment_id) {
        Log::error('Payment ID missing in webhook payload', [
            'payload' => $request->all()
        ]);
        return;
    }
    
    Log::info("Processing webhook for payment ID: $payment_id");
    
    // Try to find by ID directly
    $paymentProcess = \App\Models\PaymentProcess::find($payment_id);
    
    // If not found, try by looking in the data JSON field
    if (!$paymentProcess) {
        $paymentProcess = \App\Models\PaymentProcess::where('data->uuid', $payment_id)
            ->orWhere('data->m_payment_id', $payment_id)
            ->first();
    }
    
    // Try alternative lookup with custom_str1
    if (!$paymentProcess && $request->has('custom_str1')) {
        $contextInfo = $request->input('custom_str1');
        if (strpos($contextInfo, ':') !== false) {
            list($type, $id) = explode(':', $contextInfo);
            
            $paymentProcess = \App\Models\PaymentProcess::where('model_type', 'App\\Models\\' . ucfirst($type))
                ->where('model_id', $id)
                ->orderBy('created_at', 'desc')
                ->first();
        }
    }
    
    if (!$paymentProcess) {
        Log::error("Payment process not found", [
            'payment_id' => $payment_id,
            'custom_str1' => $request->input('custom_str1'),
            'all_data' => $request->all()
        ]);
        return;
    }
    
    // Determine payment status from PayFast
    $status = match ($request->input('payment_status')) {
        'COMPLETE' => Transaction::STATUS_PAID,
        'CANCELED' => Transaction::STATUS_CANCELED,
        default    => 'progress',
    };
    
    Log::info("Processing payment with status: $status", [
        'payment_process_id' => $paymentProcess->id,
        'user_id' => $paymentProcess->user_id ?? 'unknown'
    ]);
    
    // Process the payment status update
    $this->service->afterHook($paymentProcess->id, $status);
    
    // If payment is successful and we have token information, save the card
    if ($status === Transaction::STATUS_PAID && $request->has('token')) {
        try {
            // Make sure we have a user ID from the payment process
            $userId = $paymentProcess->user_id;
            
            if (!$userId) {
                Log::error("User ID not found in payment process", [
                    'payment_process_id' => $paymentProcess->id
                ]);
                return;
            }
            
            $token = $request->input('token');
            
            // Extract card information from the webhook data 
            $cardLastDigits = $request->input('card_last_digits') ?? 
                             $request->input('last_four') ?? 
                             substr($request->input('card_number', ''), -4) ?? 
                             '••••';
                             
            $cardBrand = $request->input('card_brand') ?? 
                        $request->input('card_type') ?? 
                        'Card';
                        
            $cardExpiry = $request->input('card_expiry') ?? 
                         $request->input('expiry_date') ?? 
                         'MM/YY';
                         
            $cardHolder = $request->input('card_holder') ?? 
                         $request->input('cardholder_name') ?? 
                         '';
            
            // Create a unique ID for the saved card
            $savedCardId = Str::uuid()->toString();
            
            // Save the card token
            \App\Models\SavedCard::create([
                'id' => $savedCardId,
                'user_id' => $userId,
                'token' => $token,
                'last_four' => $cardLastDigits,
                'card_type' => $cardBrand,
                'expiry_date' => $cardExpiry,
                'card_holder_name' => $cardHolder,
            ]);
            
            Log::info("Card token saved successfully", [
                'token' => $token,
                'user_id' => $userId,
                'saved_card_id' => $savedCardId
            ]);
        } catch (\Exception $e) {
            Log::error("Failed to save token: " . $e->getMessage(), [
                'trace' => $e->getTraceAsString(),
                'user_id' => $paymentProcess->user_id ?? 'unknown'
            ]);
        }
    }
}

private function storeTokenFromWebhook(Request $request, string $payment_id): void
{
    try {
        $token = $request->input('token');
        
        if (empty($token)) {
            \Log::warning('No token in webhook data');
            return;
        }
        
        $paymentProcess = \App\Models\PaymentProcess::find($payment_id);
        
        if (!$paymentProcess) {
            \Log::error('Payment process not found');
            return;
        }
        
        $userId = $paymentProcess->user_id;
        
        // Fetch card details using the token
        $cardService = app(PayFastCardService::class);
        $cardDetails = $cardService->fetchCardDetails($token);
        
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
        
        // Create the saved card entry
        \App\Models\SavedCard::create([
            'id' => Str::uuid(),
            'user_id' => $userId,
            'token' => $token,
            'last_four' => $cardDetails['last_four'],
            'card_type' => $cardDetails['card_type'],
            'expiry_date' => $cardDetails['expiry_date'],
            'card_holder_name' => $cardDetails['card_holder_name'],
        ]);
        
        \Log::info('Card token saved with details from API', [
            'token' => $token, 
            'user_id' => $userId,
            'details' => $cardDetails
        ]);
    } catch (\Exception $e) {
        \Log::error('Failed to store token from webhook', [
            'error' => $e->getMessage(),
            'trace' => $e->getTraceAsString(),
        ]);
    }
}

}
