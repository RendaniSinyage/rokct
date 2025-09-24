<?php

namespace App\Http\Requests\Api;

class StoreMaintenanceRecordRequest extends ApiRequest
{
    public function rules(): array
    {
        return [
            'shop_id' => ['required', 'exists:shops,id'],
            'type' => ['required', 'string', 'in:vessel,membrane,filter'],
            'reference_id' => ['required', 'string'],
            'maintenance_date' => ['required', 'date'],
        ];
    }
}
