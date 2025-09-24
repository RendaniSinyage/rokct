<?php

namespace App\Http\Requests\Payment;

use App\Http\Requests\BaseRequest;
use App\Http\Requests\Order\StoreRequest as OrderStoreRequest;
use Illuminate\Validation\Rule;

class CardPaymentRequest extends BaseRequest
{
    /**
     * Get the validation rules that apply to the request.
     *
     * @return array
     */
    public function rules(): array
    {
        $rules = [
            'card_number' => 'required|string|min:13|max:19',
            'card_holder' => 'required|string|max:255',
            'expiry_date' => 'required|string|size:5', // MM/YY format
            'cvc' => 'required|string|min:3|max:4',
            'save_card' => 'sometimes|boolean',
            
            // Order related data
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
        ];

        // Add additional order validation if cart_id is present
        if (request('cart_id')) {
            $orderRules = (new OrderStoreRequest)->rules();
            return array_merge($orderRules, $rules);
        }

        return $rules;
    }
}
