<?php

namespace App\Models\Resources;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Filter extends Model
{
    protected $table = 'filters';
    
    protected $fillable = [
        'ro_system_id',
        'external_id',
        'type',
        'location',
        'installation_date',
    ];

    protected $casts = [
        'installation_date' => 'datetime',
    ];

    public function roSystem(): BelongsTo
    {
        return $this->belongsTo(ROSystem::class, 'ro_system_id'); // Explicitly specify the foreign key
    }
}
