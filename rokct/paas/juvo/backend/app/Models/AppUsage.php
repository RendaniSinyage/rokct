<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AppUsage extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
    protected $fillable = [
        'user_id',
        'usage_date',
        'year',
        'platform',
        'app_version',
        'build_number',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array
     */
    protected $casts = [
        'usage_date' => 'date',
    ];

    /**
     * Get the user that owns the app usage record.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
