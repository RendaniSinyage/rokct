<?php
// app/Http/Resources/UserMembershipResource.php
namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class UserMembershipResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'membership_id' => $this->membership_id,
            'membership' => MembershipResource::make($this->whenLoaded('membership')),
            'start_date' => $this->start_date?->format('Y-m-d H:i:s') . 'Z',
            'end_date' => $this->end_date?->format('Y-m-d H:i:s') . 'Z',
            'is_active' => $this->is_active,
            'created_at' => $this->created_at?->format('Y-m-d H:i:s') . 'Z',
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s') . 'Z',
        ];
    }
}
