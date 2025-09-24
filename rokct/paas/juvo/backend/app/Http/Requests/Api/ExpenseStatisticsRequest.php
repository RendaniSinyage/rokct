<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class ExpenseStatisticsRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'shop_id' => 'required|integer',
            'start_date' => 'date|nullable',
            'end_date' => 'date|nullable',
        ];
    }
}
