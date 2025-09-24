<?php
// app/Models/SuccessWheelElement.php
namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class SuccessWheelElement extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'uuid',
        'shop_id',
        'name',
        'category',
        'related_pillar_id',
        'description',
        'score'
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

    public function pillar()
    {
        return $this->belongsTo(Pillar::class, 'related_pillar_id');
    }
}
