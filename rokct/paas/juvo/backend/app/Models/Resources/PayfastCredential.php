<?php

namespace App\Models\Resources;

use Illuminate\Database\Eloquent\Model;
use App\Models\Payment;

class PayfastCredential extends Model
{
    protected $table = 'payment_payloads';

    protected $fillable = [
        'payload',
    ];

    protected $casts = [
        'payload' => 'array',
    ];

    public function payment()
    {
        return $this->belongsTo(Payment::class);
    }

    // Scope to get credentials for current environment
    public function scopeCurrentEnvironment($query)
{
    return $query->whereHas('payment', function ($q) {
        $q->where('tag', 'pay-fast')->whereNull('deleted_at');
    })->whereNull('deleted_at');
}

}
