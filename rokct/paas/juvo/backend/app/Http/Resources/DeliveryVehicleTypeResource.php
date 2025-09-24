<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class DeliveryVehicleTypeResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'key' => $this->key,
            'name' => $this->name,
            'description' => $this->description,
            'active' => $this->active,
            'sort_order' => $this->sort_order,
            'max_weight_kg' => $this->max_weight_kg,
            'base_rate' => $this->base_rate,

            // Add these new fields for enhanced functionality
            // while maintaining backward compatibility
            'maxWeight' => $this->max_weight_kg, // For Flutter compatibility
            'base' => $this->base_rate ? number_format($this->base_rate, 2, '.', '') : '0.00', // For Flutter compatibility
            'capacity_kg' => $this->max_weight_kg, // Alternative naming
            'base_price' => $this->base_rate, // Alternative naming

            'delivery_man_count' => $this->whenLoaded('deliveryManSettings', function () {
                return $this->deliveryManSettings->count();
            }),
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
        ];
    }
}

