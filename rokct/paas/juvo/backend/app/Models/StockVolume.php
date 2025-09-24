<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StockVolume extends Model
{
    protected $table = 'stock_volumes';

    protected $fillable = [
        'shop_id', 
        'stock_ids', 
        'volume'
    ];

    public function shop()
    {
        return $this->belongsTo(Shop::class);
    }

    // Optional: Accessor to get stock IDs as an array
    public function getStockIdsArrayAttribute()
    {
        return explode(', ', $this->stock_ids);
    }
}
