<?php

namespace App\Http\Requests\Api;

use App\Enums\TankType;
use App\Enums\TankStatus;
use Illuminate\Validation\Rules\Enum;


class StoreTankRequest extends ApiRequest
{
    public function rules(): array
    {
        return [
            'shop_id' => ['required', 'exists:shops,id'],
            'number' => ['required', 'string'],
            'type' => ['required', new Enum(TankType::class)],
            'capacity' => ['required', 'numeric', 'min:0'],
            'status' => ['required', new Enum(TankStatus::class)],
            'pump_status' => ['required', 'array'],
            'pump_status.isOn' => ['required', 'boolean'],
            'pump_status.flowRate' => ['required', 'numeric', 'min:0'],
            'water_quality' => ['required', 'array'],
            'water_quality.ph' => ['required', 'numeric', 'between:0,14'],
            'water_quality.tds' => ['required', 'integer', 'min:0'],
            'water_quality.temperature' => ['required', 'numeric', 'min:0'],
            'water_quality.hardness' => ['required', 'integer', 'min:0'],
        ];
    }
}
