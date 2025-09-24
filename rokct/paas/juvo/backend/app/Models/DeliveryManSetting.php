<?php
// app/Models/DeliveryManSetting.php

namespace App\Models;

use App\Traits\Loadable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class DeliveryManSetting extends Model
{
    use HasFactory, Loadable, SoftDeletes;

    protected $guarded = ['id'];
    protected $table = 'deliveryman_settings';
    protected $casts = ['location' => 'array'];

    // Keep old constants for backward compatibility
    const BENZINE = 'benzine';

    /**
     * Get dynamic TYPE_OF_TECHNIQUES from database
     * This replaces the old hardcoded constant
     */
    public static function TYPE_OF_TECHNIQUES(): array
    {
        return self::getAvailableVehicleTypes();
    }

    /**
     * Get available vehicle types from database
     */
    public static function getAvailableVehicleTypes(): array
    {
        try {
            return \App\Models\DeliveryVehicleType::where('active', true)
                                                 ->orderBy('sort_order')
                                                 ->pluck('key', 'key')
                                                 ->toArray();
        } catch (\Exception $e) {
            // Fallback if table doesn't exist
            return [
                'motorbike' => 'motorbike',
                'bike' => 'bike',
                'foot' => 'foot'
            ];
        }
    }

    public function deliveryMan(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function vehicleType(): BelongsTo
    {
        return $this->belongsTo(\App\Models\DeliveryVehicleType::class, 'type_of_technique', 'key');
    }
}

