<?php
// app/Models/StrategicObjective.php
namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class StrategicObjective extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'uuid',
        'shop_id',
        'pillar_id',
        'title',
        'description',
        'is_90_day_priority',
        'time_horizon',
        'status',
        'start_date',
        'target_date',
        'completion_date'
    ];

    protected $casts = [
        'is_90_day_priority' => 'boolean',
        'start_date' => 'date',
        'target_date' => 'date',
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

    public function pillar()
    {
        return $this->belongsTo(Pillar::class);
    }

    public function kpis()
    {
        return $this->hasMany(Kpi::class, 'objective_id');
    }

    public function tasks()
    {
        return $this->hasMany(TodoTask::class, 'objective_id');
    }

    public function personalMasteryGoals()
    {
        return $this->hasMany(PersonalMasteryGoal::class, 'related_objective_id');
    }
}


