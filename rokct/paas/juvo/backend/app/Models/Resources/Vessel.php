<?php

namespace App\Models\Resources;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Vessel extends Model
{
    protected $table = 'vessels';
    
    protected $fillable = [
        'ro_system_id',  // Make sure this matches
        'external_id',
        'type',
        'installation_date',
        'last_maintenance_date',
        'current_stage',
        'maintenance_start_time',
    ];

    protected $casts = [
        'installation_date' => 'datetime',
        'last_maintenance_date' => 'datetime',
        'maintenance_start_time' => 'datetime',
    ];

    public function roSystem(): BelongsTo
    {
        return $this->belongsTo(ROSystem::class, 'ro_system_id'); // Explicitly specify the foreign key
    }
}
