<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class LoanApplication extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
    protected $fillable = [
        'user_id',
        'id_number',
        'amount',
        'status',
        'documents',
        'additional_data',
        'contract_accepted_at',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array
     */
    protected $casts = [
        'documents' => 'json',
        'additional_data' => 'json',
        'contract_accepted_at' => 'datetime',
    ];

    /**
     * Get the user that owns the loan application.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the contract associated with the loan application.
     */
    public function contract(): HasOne
    {
        return $this->hasOne(LoanContract::class);
    }
}
