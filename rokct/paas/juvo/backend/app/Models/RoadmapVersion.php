<?php
// app/Models/RoadmapVersion.php
namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class RoadmapVersion extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'uuid',
        'app_id',
        'version_number',
        'status',
        'description',
        'features',
        'release_date'
    ];

    protected $casts = [
        'features' => 'array',
        'release_date' => 'date',
    ];

    protected static function boot()
    {
        parent::boot();
        
        static::creating(function ($model) {
            $model->uuid = (string) Str::uuid();
        });
    }

    public function app()
    {
        return $this->belongsTo(App::class);
    }

    public function tasks()
    {
        return $this->hasMany(TodoTask::class, 'roadmap_version', 'version_number')
                   ->where('app_id', $this->app_id);
    }
}
