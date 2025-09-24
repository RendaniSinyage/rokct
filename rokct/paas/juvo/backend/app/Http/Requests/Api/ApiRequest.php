<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Support\Facades\Log;

class ApiRequest extends FormRequest
{
    protected $requestedShopId;
    protected $userShopId;

    public function authorize(): bool
    {
        return true;  // Base authorization can be overridden in child classes
    }

    protected function failedValidation(Validator $validator)
    {
        throw new HttpResponseException(response()->json([
            'message' => 'Validation error',
            'errors' => $validator->errors()
        ], 422));
    }

    protected function failedAuthorization()
    {
        throw new HttpResponseException(response()->json([
            'message' => 'You are not authorized to access this resource',
            'debug_info' => [
                'requested_shop_id' => $this->requestedShopId,
                'user_shop_id' => $this->userShopId,
                'route_parameters' => $this->route()->parameters(),
                'input_shop_id' => $this->input('shop_id')
            ]
        ], 403));
    }
}
