<?php

namespace App\Models\Weather;

use Illuminate\Database\Eloquent\Model;

class WeatherData extends Model
{
    protected $fillable = [
        'city_name',
        'country_code',
        'request_count',
        'last_fetched_at',
        'last_request_at',
        'is_active'
    ];

    protected $casts = [
        'last_fetched_at' => 'datetime',
        'last_request_at' => 'datetime',
        'is_active' => 'boolean'
    ];

    /**
     * Track a location request - only stores location, not weather data
     */
    public static function trackLocation($cityName, $countryCode)
    {
        try {
            // Clean the city name and country code
            $cleanCityName = trim(strtolower($cityName));
            $cleanCountryCode = trim(strtolower($countryCode));

            // If it's musina-nancefield or a variation of Messina, use the default
            if (str_contains($cleanCityName, 'messi') || 
                str_contains($cleanCityName, 'musina-nancefield')) {
                $cleanCityName = 'messina';
                $cleanCountryCode = 'za';
            }

            // Use updateOrCreate to avoid duplicates
            $weatherData = self::updateOrCreate(
                [
                    'city_name' => $cleanCityName,
                    'country_code' => $cleanCountryCode
                ],
                [
                    'last_request_at' => now(),
                    'is_active' => true
                ]
            );

            // Increment request count
            $weatherData->increment('request_count');

            return $weatherData;

        } catch (\Exception $e) {
            \Log::error("Error in WeatherData::trackLocation", [
                'original_city' => $cityName,
                'original_country' => $countryCode,
                'clean_city' => $cleanCityName ?? null,
                'clean_country' => $cleanCountryCode ?? null,
                'error' => $e->getMessage()
            ]);
            throw $e;
        }
    }

    /**
     * Get all active locations for scheduled fetching
     */
    public static function getActiveLocations()
    {
        return self::where('is_active', true)->get();
    }

    /**
     * Mark location as fetched
     */
    public function markAsFetched()
    {
        $this->update([
            'last_fetched_at' => now()
        ]);
    }

    /**
     * Get location string for API calls
     */
    public function getLocationString()
    {
        return "{$this->city_name},{$this->country_code}";
    }

    /**
     * Get Redis cache key for this location
     */
    public function getCacheKey($days = 3, $alerts = 'yes')
    {
        return "weather_{$this->city_name}_{$this->country_code}_{$days}_{$alerts}";
    }

    /**
     * Deactivate locations that haven't been requested in 30 days
     */
    public static function deactivateOldLocations()
    {
        self::where('last_request_at', '<', now()->subDays(30))
            ->update(['is_active' => false]);
    }
}
