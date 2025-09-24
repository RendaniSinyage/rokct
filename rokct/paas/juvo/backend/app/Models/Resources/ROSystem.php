<?php

namespace App\Models\Resources;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ROSystem extends Model
{

    protected $table = 'ro_systems';

    protected $fillable = [
        'shop_id',
        'membrane_count',
        'membrane_installation_date',
    ];

    protected $casts = [
        'membrane_installation_date' => 'datetime',
    ];

    public function shop(): BelongsTo
    {
        return $this->belongsTo(Shop::class);
    }

    public function vessels(): HasMany
{
    return $this->hasMany(Vessel::class, 'ro_system_id');
}

    public function filters(): HasMany
{
    return $this->hasMany(Filter::class, 'ro_system_id');
}
}
