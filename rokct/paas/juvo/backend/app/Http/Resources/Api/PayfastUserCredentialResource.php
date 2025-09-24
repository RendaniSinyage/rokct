<?php

namespace App\Http\Resources\Api;

use Illuminate\Http\Resources\Json\JsonResource;

class PayfastUserCredentialResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'merchant_key' => $this->payload['merchant_key'] ?? null,
            'passphrase' => $this->payload['pass_phrase'] ?? null,
            'is_sandbox' => (bool) $this->payment->sandbox, // Cast to boolean
        'is_active' => (bool) $this->payment->active, 
        ];
    }
}
