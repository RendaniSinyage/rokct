<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MeterReading extends Model
{
    use HasFactory;

    protected $fillable = [
        'meterId',
        'reading',
        'timestamp',
        'userId',
        'shopId',
        'imagePath',
    ];

    protected $casts = [
        'timestamp' => 'datetime',
    ];
}
