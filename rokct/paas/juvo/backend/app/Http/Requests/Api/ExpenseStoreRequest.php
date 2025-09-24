<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class ExpenseStoreRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'shop_id' => 'required|integer',
            'type_id' => 'required|integer|exists:expenses_type,id',
            'item_code' => 'nullable|string',
            'qty' => 'numeric|default:1.0',
            'price' => 'required|numeric',
            'description' => 'required|string',
            'note' => 'nullable|string',
            'meter_id' => 'nullable|integer',
            'kwh' => 'nullable|numeric',
            'litres' => 'nullable|numeric',
            'supplier' => 'nullable|string',
            'invoice_number' => 'nullable|string',
        ];
    }
}

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
