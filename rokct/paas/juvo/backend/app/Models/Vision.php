<?php
// app/Models/Vision.php
namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class Vision extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'uuid',
        'shop_id',
        'statement',
        'effective_date',
        'end_date',
        'is_active',
        'created_by'
    ];

    protected $casts = [
        'effective_date' => 'date',
        'end_date' => 'date',
        'is_active' => 'boolean',
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

    public function pillars()
    {
        return $this->hasMany(Pillar::class);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}


