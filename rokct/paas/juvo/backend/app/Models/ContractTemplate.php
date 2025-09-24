<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ContractTemplate extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
    protected $fillable = [
        'title',
        'content',
        'loan_type',
        'min_amount',
        'max_amount',
        'is_default',
        'base_interest_rate',
        'default_term_months',
        'additional_terms',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array
     */
    protected $casts = [
        'min_amount' => 'float',
        'max_amount' => 'float',
        'is_default' => 'boolean',
        'base_interest_rate' => 'float',
        'default_term_months' => 'integer',
        'additional_terms' => 'json',
    ];
}
