<?php

namespace App\Http\Resources\Api;

use Illuminate\Http\Resources\Json\JsonResource;

class FilterResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->external_id,
            'type' => $this->type,
            'location' => $this->location,
            'installation_date' => $this->installation_date,
        ];
    }
}
