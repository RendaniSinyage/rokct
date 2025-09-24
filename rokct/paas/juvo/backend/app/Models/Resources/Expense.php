<?php

namespace App\Models\Resources;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Expense extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'shop_id',
        'item_code',
        'qty',
        'price',
        'description',
        'note',
        'meter_id',
        'kwh',
        'litres',
        'status',
        'type_id',
        'supplier',
        'invoice_number',
    ];

    protected $casts = [
        'shop_id' => 'integer',
        'qty' => 'float',
        'price' => 'float',
        'meter_id' => 'integer',
        'kwh' => 'float',
        'litres' => 'float',
        'type_id' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    protected $attributes = [
        'qty' => 1.0,
        'status' => 'progress',
    ];

    public function shop(): BelongsTo
    {
        return $this->belongsTo(Shop::class);
    }

    public function type(): BelongsTo
    {
        return $this->belongsTo(ExpenseType::class, 'type_id');
    }
}
