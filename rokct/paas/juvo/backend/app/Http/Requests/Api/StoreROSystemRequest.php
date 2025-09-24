<?php

namespace App\Http\Requests\Api;

use App\Enums\FilterType;
use App\Enums\FilterLocation;
use App\Enums\VesselType;
use Illuminate\Validation\Rules\Enum;

class StoreROSystemRequest extends ApiRequest
{
    public function rules(): array
    {
        return [
            'shop_id' => ['required', 'exists:shops,id'],
            'membrane_count' => ['required', 'integer', 'min:1'],
            'membrane_installation_date' => ['required', 'date'],
            'filters' => ['required', 'array', 'min:1'],
            'filters.*.id' => ['required', 'string'],
            'filters.*.type' => ['required', new Enum(FilterType::class)],
            'filters.*.location' => ['required', new Enum(FilterLocation::class)],
            'filters.*.installation_date' => ['required', 'date'],
            'vessels' => ['required', 'array', 'min:1'],
            'vessels.*.id' => ['required', 'string'],
            'vessels.*.type' => ['required', new Enum(VesselType::class)],
            'vessels.*.installation_date' => ['required', 'date'],
        ];
    }
}

