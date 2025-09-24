<?php

namespace App\Models\Resources;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Tank extends Model
{
protected $dateFormat = 'Y-m-d H:i:s';

public function freshTimestamp() {
    return now()->setTimezone('Africa/Johannesburg');
}
protected $table = 'tanks';
    protected $fillable = [
        'shop_id',
        'number',
        'type',
        'capacity',
        'status',
        'pump_status',
        'water_quality',
        'last_full',
    ];

    protected $casts = [
        'capacity' => 'decimal:2',
        'pump_status' => 'json',
        'water_quality' => 'json',
        'last_full' => 'datetime',
        'created_at' => 'datetime',  // Add this
        'updated_at' => 'datetime'   // Add this
    ];

    public function shop(): BelongsTo
    {
        return $this->belongsTo(Shop::class);
    }
}
