<?php
// app/Models/TodoTask.php
namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class TodoTask extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'uuid',
        'shop_id',
        'kpi_id',
        'objective_id',
        'title',
        'description',
        'due_date',
        'assigned_to',
        'status',
        'priority',
        'app_id',
        'roadmap_version',
        'tender_ocid',
        'tender_data',
        'platforms', // Added this field
    ];

    protected $casts = [
        'due_date' => 'date',
        'tender_data' => 'array',
        'platforms' => 'array', // Cast to array
    ];

    protected static function boot()
    {
        parent::boot();
        
        static::creating(function ($model) {
            $model->uuid = (string) Str::uuid();
        });
    }

    // Relationships stay the same
    public function shop()
    {
        return $this->belongsTo(Shop::class);
    }

    public function kpi()
    {
        return $this->belongsTo(Kpi::class);
    }

    public function strategicObjective()
    {
        return $this->belongsTo(StrategicObjective::class, 'objective_id');
    }

    public function assignee()
    {
        return $this->belongsTo(User::class, 'assigned_to');
    }

    public function app()
    {
        return $this->belongsTo(App::class);
    }
}
