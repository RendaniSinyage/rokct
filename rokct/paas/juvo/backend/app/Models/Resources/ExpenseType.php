<?php

namespace App\Models\Resources;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ExpenseType extends Model
{
    protected $table = 'expenses_type';

    protected $fillable = [
        'name'
    ];

    public function expenses(): HasMany
    {
        return $this->hasMany(Expense::class, 'type_id');
    }
}
