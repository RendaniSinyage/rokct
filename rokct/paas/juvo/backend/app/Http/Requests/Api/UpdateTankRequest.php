<?php

namespace App\Http\Requests\Api;

use App\Enums\TankStatus;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rules\Enum;


class UpdateTankRequest extends ApiRequest
{
    
    public function authorize(): bool
    {
        // Get the tank from route parameters
        $tank = $this->route('tank');
        
        // Get the authenticated user
        $user = auth('sanctum')->user();
        
        Log::info('Authorization Check', [
            'user' => $user?->toArray(),
            'tank' => $tank?->toArray(),
            'user_shop' => $user?->shop?->toArray()
        ]);

        // Store IDs for debug info
        $this->userShopId = $user?->shop?->id;
        $this->requestedShopId = $tank?->shop_id;

        // Authorization logic: user's shop must match tank's shop
        return $user && $tank && $user->shop && $user->shop->id === $tank->shop_id;
    }

    public function rules(): array
    {
          return [
        'status' => ['sometimes', new Enum(TankStatus::class)],
        'last_full' => ['sometimes', 'nullable', 'date'],
        'pump_status' => ['sometimes', 'array'],
        'pump_status.isOn' => ['required_with:pump_status', 'boolean'],
        'pump_status.flowRate' => ['sometimes', 'nullable', 'numeric', 'min:0'], // Changed to sometimes,nullable
        'water_quality' => ['sometimes', 'array'],
        'water_quality.ph' => ['required_with:water_quality', 'numeric', 'between:0,14'],
        'water_quality.tds' => ['required_with:water_quality', 'integer', 'min:0'],
        'water_quality.temperature' => ['required_with:water_quality', 'numeric', 'min:0'],
        'water_quality.hardness' => ['required_with:water_quality', 'integer', 'min:0'],
        'capacity' => ['sometimes', 'numeric', 'min:0'],
    ];
    }
}

