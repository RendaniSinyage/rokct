<?php

namespace App\Models\Resources;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MaintenanceRecord extends Model
{
    protected $table = 'maintenance_records';
    protected $fillable = [
        'shop_id',
        'type',
        'reference_id',
        'maintenance_date',
    ];

    protected $casts = [
        'maintenance_date' => 'datetime',
    ];

    public function shop(): BelongsTo
    {
        return $this->belongsTo(Shop::class);
    }
}
