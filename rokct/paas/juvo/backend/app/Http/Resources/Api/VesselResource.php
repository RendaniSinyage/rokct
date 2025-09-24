<?php

namespace App\Http\Resources\Api;

use Illuminate\Http\Resources\Json\JsonResource;

class VesselResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->external_id,
            'type' => $this->type,
            'installation_date' => $this->installation_date,
            'last_maintenance_date' => $this->last_maintenance_date,
            'current_stage' => $this->current_stage,
            'maintenance_start_time' => $this->maintenance_start_time,
        ];
    }
}


