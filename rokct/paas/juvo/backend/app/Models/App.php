<?php
// app/Models/App.php
namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class App extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'uuid',
        'shop_id',
        'name',
        'package_name',
        'description',
        'platform',
        'icon',
        'current_version'
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

    public function roadmapVersions()
    {
        return $this->hasMany(RoadmapVersion::class);
    }

    public function tasks()
    {
        return $this->hasMany(TodoTask::class);
    }
}


