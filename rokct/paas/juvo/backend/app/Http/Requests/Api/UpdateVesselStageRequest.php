<?php

namespace App\Http\Requests\Api;

class UpdateVesselStageRequest extends ApiRequest
{
    public function rules(): array
    {
        return [
            'stage' => ['required', 'string', new Enum(MaintenanceStage::class)],
            'start_time' => ['required', 'date'],
        ];
    }
}
