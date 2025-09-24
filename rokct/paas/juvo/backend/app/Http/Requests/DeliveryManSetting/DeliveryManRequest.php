<?php
// app/Http/Requests/DeliveryManSetting/DeliveryManRequest.php

namespace App\Http\Requests\DeliveryManSetting;

use App\Http\Requests\BaseRequest;
use App\Models\DeliveryManSetting;
use Illuminate\Validation\Rule;

class DeliveryManRequest extends BaseRequest
{
    public function rules(): array
    {
        return [
            // Change this line from:
            // 'type_of_technique' => ['required', 'string', Rule::in(DeliveryManSetting::TYPE_OF_TECHNIQUES)],
            // To:
            'type_of_technique' => ['required', 'string', Rule::in(DeliveryManSetting::getAvailableVehicleTypes())],
            
            'brand' => 'required|string',
            'model' => 'required|string',
            'number' => 'required|string',
            'color' => 'required|string',
            'online' => 'required|boolean',
            'width' => 'integer|min:0',
            'height' => 'integer|min:0',
            'length' => 'integer|min:0',
            'kg' => 'integer|min:0',
            'location' => 'array',
            'location.latitude' => is_array(request('location')) ? 'required|numeric' : 'numeric',
            'location.longitude' => is_array(request('location')) ? 'required|numeric' : 'numeric',
            'images' => 'array',
            'images.*' => 'string',
        ];
    }
}
