<?php
// app/Models/Membership.php
namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Membership extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'type',
        'price',
        'duration',
        'duration_unit',
        'description',
        'is_active',
    ];

    protected $casts = [
        'price' => 'float',
        'duration' => 'integer',
        'is_active' => 'boolean',
    ];

    /**
     * Get all user memberships for this membership plan.
     */
    public function userMemberships(): HasMany
    {
        return $this->hasMany(UserMembership::class);
    }
}
