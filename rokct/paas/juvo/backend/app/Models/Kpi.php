<?php
// app/Models/Kpi.php
namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class Kpi extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'uuid',
        'shop_id',
        'objective_id',
        'metric',
        'target_value',
        'current_value',
        'unit',
        'due_date',
        'status',
        'completion_date'
    ];

    protected $casts = [
        'due_date' => 'date',
        'completion_date' => 'date',
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

    public function strategicObjective()
    {
        return $this->belongsTo(StrategicObjective::class, 'objective_id');
    }

    public function tasks()
    {
        return $this->hasMany(TodoTask::class);
    }
}


