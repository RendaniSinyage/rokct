<?php
// app/Models/PersonalMasteryGoal.php
namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class PersonalMasteryGoal extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'uuid',
        'user_id',
        'area',
        'title',
        'description',
        'related_objective_id',
        'target_date',
        'status'
    ];

    protected $casts = [
        'target_date' => 'date',
    ];

    protected static function boot()
    {
        parent::boot();
        
        static::creating(function ($model) {
            $model->uuid = (string) Str::uuid();
        });
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function strategicObjective()
    {
        return $this->belongsTo(StrategicObjective::class, 'related_objective_id');
    }
}


