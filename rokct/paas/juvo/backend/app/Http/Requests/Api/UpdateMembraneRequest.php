<?php

namespace App\Http\Requests\Api;

class UpdateMembraneRequest extends ApiRequest
{
    public function rules(): array
    {
        return [
            'membrane_count' => ['required', 'integer', 'min:1'],
            'membrane_installation_date' => ['required', 'date']
        ];
    }
}
