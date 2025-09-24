<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class ExpenseUpdateRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'type_id' => 'integer|exists:expenses_type,id',
            'item_code' => 'nullable|string',
            'qty' => 'numeric',
            'price' => 'numeric',
            'description' => 'string',
            'note' => 'nullable|string',
            'meter_id' => 'nullable|integer',
            'kwh' => 'nullable|numeric',
            'litres' => 'nullable|numeric',
            'supplier' => 'nullable|string',
            'invoice_number' => 'nullable|string',
        ];
    }
}
