<?php

namespace App\Http\Resources;

use App\Models\Shop;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MobileShopResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param  Request  $request
     * @return array
     */
    public function toArray($request): array
    {
        /** @var Shop|JsonResource $this */
        // Start with the original shop resource data
        $data = parent::toArray($request);
        
        // Explicitly cast boolean fields
        if (isset($data['open'])) {
            $data['open'] = (bool)$data['open'];
        }
        
        if (isset($data['visibility'])) {
            $data['visibility'] = (bool)$data['visibility'];
        }
        
        if (isset($data['verify'])) {
            $data['verify'] = (bool)$data['verify'];
        }
        
        return $data;
    }
}
