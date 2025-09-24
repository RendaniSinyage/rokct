<?php

namespace App\Http\Resources\Api;

use Illuminate\Http\Resources\Json\JsonResource;

class ROSystemResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'shop_id' => $this->shop_id,
            'filters' => FilterResource::collection($this->filters),
            'vessels' => VesselResource::collection($this->vessels),
            'membrane_count' => $this->membrane_count,
            'membrane_installation_date' => $this->membrane_installation_date,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
