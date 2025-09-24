<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class ExpenseIndexRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'shop_id' => 'required|integer',
            'type_id' => 'integer|nullable',
            'start_date' => 'date|nullable',
            'end_date' => 'date|nullable',
            'per_page' => 'integer|nullable',
        ];
    }
}
