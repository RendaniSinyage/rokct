<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class ExpensePartialUpdateRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'type_id' => 'integer|exists:expenses_type,id|nullable',
            'item_code' => 'string|nullable',
            'qty' => 'numeric|nullable',
            'price' => 'numeric|nullable',
            'description' => 'string|nullable',
            'note' => 'string|nullable',
            'meter_id' => 'integer|nullable',
            'kwh' => 'numeric|nullable',
            'litres' => 'nullable|numeric',
            'supplier' => 'string|nullable',
            'invoice_number' => 'string|nullable',
        ];
    }
}
