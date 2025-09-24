<?php

namespace App\Http\Resources\Api;

use Illuminate\Http\Resources\Json\JsonResource;

class TankResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'shop_id' => $this->shop_id,
            'number' => $this->number,
            'type' => $this->type,
            'capacity' => $this->capacity,
            'status' => $this->status,
            'pump_status' => $this->pump_status,
            'water_quality' => $this->water_quality,
            'last_full' => $this->last_full,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
