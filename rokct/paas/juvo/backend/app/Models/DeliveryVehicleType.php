<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class DeliveryVehicleType extends Model
{
    use HasFactory;

    protected $fillable = [
        'key',
        'name',
        'description',
        'active',
        'sort_order',
        'max_weight_kg',
        'base_rate'
    ];

    protected $casts = [
        'active' => 'boolean',
        'max_weight_kg' => 'integer',
        'base_rate' => 'decimal:2',
        'sort_order' => 'integer'
    ];

    /**
     * Get active vehicle types for dropdown
     */
    public static function getActiveTypes(): array
    {
        return self::where('active', true)
                   ->orderBy('sort_order')
                   ->pluck('name', 'key')
                   ->toArray();
    }

    /**
     * Get active vehicle types with weight and rate data
     */
    public static function getActiveTypesWithData(): array
    {
        return self::where('active', true)
                   ->orderBy('sort_order')
                   ->get(['key', 'name', 'max_weight_kg', 'base_rate'])
                   ->map(function ($type) {
                       return [
                           'key' => $type->key,
                           'name' => $type->name,
                           'maxWeight' => $type->max_weight_kg,
                           'base' => $type->base_rate ? number_format($type->base_rate, 2, '.', '') : '0.00',
                           'max_weight_kg' => $type->max_weight_kg,
                           'base_rate' => $type->base_rate,
                       ];
                   })
                   ->toArray();
    }

    /**
     * Get all active vehicle keys
     */
    public static function getAllActiveVehicles(): array
    {
        return self::where('active', true)
                   ->orderBy('sort_order')
                   ->pluck('key')
                   ->toArray();
    }

    /**
     * Get vehicle types suitable for retail orders (≤100kg)
     */
    public static function getRetailVehicles(): array
    {
        return self::where('active', true)
                   ->where('max_weight_kg', '<=', 100)
                   ->orderBy('sort_order')
                   ->get(['key', 'name', 'max_weight_kg', 'base_rate'])
                   ->toArray();
    }

    /**
     * Get vehicle types suitable for agricultural orders (>100kg)
     */
    public static function getAgricultureVehicles(): array
    {
        return self::where('active', true)
                   ->where('max_weight_kg', '>', 100)
                   ->orderBy('sort_order')
                   ->get(['key', 'name', 'max_weight_kg', 'base_rate'])
                   ->toArray();
    }

    /**
     * Find suitable vehicles for a given weight
     */
    public static function getSuitableVehicles(int $weightKg): array
    {
        return self::where('active', true)
                   ->where(function ($query) use ($weightKg) {
                       $query->where('max_weight_kg', '>=', $weightKg)
                             ->orWhereNull('max_weight_kg'); // For vehicles without weight limit
                   })
                   ->orderBy('max_weight_kg', 'asc') // Order by capacity (smallest suitable first)
                   ->orderBy('base_rate', 'asc')     // Then by price (cheapest first)
                   ->get(['key', 'name', 'max_weight_kg', 'base_rate'])
                   ->toArray();
    }

    /**
     * Get the most economical vehicle for a given weight
     */
    public static function getMostEconomicalVehicle(int $weightKg): ?self
    {
        return self::where('active', true)
                   ->where(function ($query) use ($weightKg) {
                       $query->where('max_weight_kg', '>=', $weightKg)
                             ->orWhereNull('max_weight_kg');
                   })
                   ->orderBy('base_rate', 'asc')
                   ->first();
    }

    /**
     * Calculate delivery cost based on vehicle type and additional factors
     */
    public function calculateDeliveryCost(float $distance = 0, int $weightKg = 0): float
    {
        $baseCost = $this->base_rate ?? 0;

        // Add distance-based cost (example: R2 per km)
        $distanceCost = $distance * 2;

        // Add weight-based cost if over 50% of vehicle capacity
        $weightCost = 0;
        if ($this->max_weight_kg && $weightKg > ($this->max_weight_kg * 0.5)) {
            $weightCost = ($weightKg - ($this->max_weight_kg * 0.5)) * 0.5; // R0.50 per extra kg
        }

        return $baseCost + $distanceCost + $weightCost;
    }

    /**
     * Check if this vehicle can handle a specific weight
     */
    public function canHandleWeight(int $weightKg): bool
    {
        if (!$this->max_weight_kg) {
            return true; // No weight limit
        }

        return $weightKg <= $this->max_weight_kg;
    }

    /**
     * Get display name with capacity information
     */
    public function getDisplayNameAttribute(): string
    {
        if ($this->max_weight_kg) {
            return "{$this->name} (Max: {$this->max_weight_kg}kg)";
        }

        return $this->name;
    }

    /**
     * Get formatted base rate
     */
    public function getFormattedBaseRateAttribute(): string
    {
        return $this->base_rate ? 'R' . number_format($this->base_rate, 2) : 'R0.00';
    }

    /**
     * Delivery man settings using this vehicle type
     */
    public function deliveryManSettings(): HasMany
    {
        return $this->hasMany(DeliveryManSetting::class, 'type_of_technique', 'key');
    }

    /**
     * Scope for active vehicles
     */
    public function scopeActive($query)
    {
        return $query->where('active', true);
    }

    /**
     * Scope for retail vehicles (≤100kg)
     */
    public function scopeRetail($query)
    {
        return $query->where('max_weight_kg', '<=', 100);
    }

    /**
     * Scope for agricultural vehicles (>100kg)
     */
    public function scopeAgriculture($query)
    {
        return $query->where('max_weight_kg', '>', 100);
    }

    /**
     * Scope for vehicles that can handle specific weight
     */
    public function scopeCanHandle($query, int $weightKg)
    {
        return $query->where(function ($q) use ($weightKg) {
            $q->where('max_weight_kg', '>=', $weightKg)
              ->orWhereNull('max_weight_kg');
        });
    }

    /**
     * Scope for vehicles ordered by efficiency (capacity vs cost)
     */
    public function scopeOrderByEfficiency($query)
    {
        return $query->orderByRaw('COALESCE(max_weight_kg / NULLIF(base_rate, 0), 0) DESC');
    }
}

