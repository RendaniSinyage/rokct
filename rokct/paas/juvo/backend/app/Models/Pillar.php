<?php
// app/Models/Pillar.php
namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class Pillar extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'uuid',
        'shop_id',
        'vision_id',
        'name',
        'description',
        'icon',
        'color',
        'display_order'
    ];

    protected static function boot()
    {
        parent::boot();
        
        static::creating(function ($model) {
            $model->uuid = (string) Str::uuid();
        });
    }

    public function shop()
    {
        return $this->belongsTo(Shop::class);
    }

    public function vision()
    {
        return $this->belongsTo(Vision::class);
    }

    public function strategicObjectives()
    {
        return $this->hasMany(StrategicObjective::class);
    }

    public function successWheelElements()
    {
        return $this->hasMany(SuccessWheelElement::class, 'related_pillar_id');
    }
}


