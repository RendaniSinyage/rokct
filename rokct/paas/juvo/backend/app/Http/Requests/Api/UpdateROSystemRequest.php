<?php

namespace App\Http\Requests\Api;

class UpdateROSystemRequest extends ApiRequest
{
    public function rules(): array
    {
        return [
            'shop_id' => ['required', 'exists:shops,id'],
            'membrane_count' => ['required', 'integer', 'min:1'],
            'membrane_installation_date' => ['required', 'date'],
            'filters' => ['required', 'array', 'min:1'],
            'filters.*.id' => ['required', 'string'],
            'filters.*.type' => ['required', 'string', 'in:sediment,carbonBlock,birm'],
            'filters.*.location' => ['required', 'string', 'in:pre,ro,post'],
            'filters.*.installation_date' => ['required', 'date'],
            'vessels' => ['required', 'array', 'min:1'],
            'vessels.*.id' => ['required', 'string'],
            'vessels.*.type' => ['required', 'string', 'in:megaChar,softener'],
            'vessels.*.installation_date' => ['required', 'date'],
        ];
    }
}
