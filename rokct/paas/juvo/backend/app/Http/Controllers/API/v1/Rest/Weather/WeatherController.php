<?php

namespace App\Http\Controllers\API\v1\Rest\Weather;

use App\Http\Controllers\Controller;
use App\Services\WeatherService\WeatherService;
use App\Traits\CountryCodeMapper;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

class WeatherController extends Controller
{
    use CountryCodeMapper;

    protected $weatherService;
    protected $defaultLocation = 'messina,za';
    protected $cacheMinutes = 180; // 3 hours

    public function __construct(WeatherService $weatherService)
    {
        $this->weatherService = $weatherService;
    }

    protected function shouldUseDefaultLocation($cityQuery)
    {
        $cityQuery = strtolower($cityQuery);
        return str_contains($cityQuery, 'messi') || 
               str_contains($cityQuery, 'musina-nancefield');
    }

    protected function parseLocationQuery($q)
    {
        $parts = explode(',', strtolower($q));
        $city = trim($parts[0]);
        
        if (str_contains($city, 'musina-nancefield')) {
            return [
                'city' => 'messina',
                'countryCode' => 'za'
            ];
        }

        return [
            'city' => $city,
            'countryCode' => trim($parts[1] ?? '')
        ];
    }

    protected function generateCacheKey($location, $days, $alerts)
    {
        // Clean location for cache key
        $cleanLocation = strtolower(str_replace([',', ' '], ['_', '_'], $location));
        return "weather_{$cleanLocation}_{$days}_{$alerts}";
    }

    protected function formatWeatherResponse($weatherData)
    {
        return [
            'location' => [
                'name' => $weatherData['location']['name'] ?? '',
                'region' => $weatherData['location']['region'] ?? '',
                'country' => $weatherData['location']['country'] ?? '',
                'lat' => $weatherData['location']['lat'] ?? null,
                'lon' => $weatherData['location']['lon'] ?? null,
                'tz_id' => $weatherData['location']['tz_id'] ?? '',
                'localtime_epoch' => $weatherData['location']['localtime_epoch'] ?? 0,
                'localtime' => $weatherData['location']['localtime'] ?? ''
            ],
            'current' => $weatherData['current'] ?? [],
            'forecast' => [
                'forecastday' => $weatherData['forecast']['forecastday'] ?? []
            ],
            'alerts' => [
                'alert' => $weatherData['alerts']['alert'] ?? []
            ],
            '_cached_at' => $weatherData['_cached_at'] ?? now()->toDateTimeString(),
            '_redis_cached' => true
        ];
    }

    public function getWeather(Request $request)
    {
        try {
            $validated = $request->validate([
                'q' => 'required|string',
                'days' => 'integer|between:1,10',
                'alerts' => 'string|in:yes,no'
            ]);

            $locationQuery = $validated['q'];
            $days = $validated['days'] ?? 3;
            $alerts = $validated['alerts'] ?? 'yes';
            $parsedLocation = $this->parseLocationQuery($locationQuery);

            // Handle coordinate requests and fallback to default location
            if (preg_match('/^-?\d+\.?\d*,\s*-?\d+\.?\d*$/', $locationQuery) || 
                $this->shouldUseDefaultLocation($parsedLocation['city'])) {
                $locationQuery = $this->defaultLocation;
                $parsedLocation = $this->parseLocationQuery($this->defaultLocation);
            }

            // Generate cache key
            $cacheKey = $this->generateCacheKey($locationQuery, $days, $alerts);

            // Try to get from Redis cache first
            $cachedResponse = Cache::get($cacheKey);
            if ($cachedResponse) {
                Log::info("Weather served from Redis cache", [
                    'location' => $locationQuery,
                    'cache_key' => $cacheKey,
                    'cached_at' => $cachedResponse['_cached_at'] ?? 'unknown'
                ]);
                
                // Add cache indicator
                $cachedResponse['_served_from'] = 'redis_cache';
                return response()->json($cachedResponse);
            }

            Log::info("Weather cache miss, fetching fresh data", [
                'location' => $locationQuery,
                'cache_key' => $cacheKey
            ]);

            // Get fresh weather data from WeatherService
            $weatherData = $this->weatherService->getWeatherData(
                $locationQuery,
                $days,
                $alerts
            );

            // Validate country match
            if (!$this->validateCountryMatch(
                $parsedLocation['countryCode'],
                $weatherData['location']['country'] ?? ''
            )) {
                Log::warning("Country mismatch for query: {$locationQuery}");
                
                // Retry with default location
                $locationQuery = $this->defaultLocation;
                $cacheKey = $this->generateCacheKey($locationQuery, $days, $alerts);
                
                // Check cache for default location
                $cachedResponse = Cache::get($cacheKey);
                if ($cachedResponse) {
                    $cachedResponse['_served_from'] = 'redis_cache_fallback';
                    return response()->json($cachedResponse);
                }
                
                $weatherData = $this->weatherService->getWeatherData(
                    $this->defaultLocation,
                    $days,
                    $alerts
                );
            }

            // Format the response
            $responseData = $this->formatWeatherResponse($weatherData);
            $responseData['_served_from'] = 'fresh_api';

            // Store in Redis cache
            Cache::put($cacheKey, $responseData, now()->addMinutes($this->cacheMinutes));

            Log::info("Weather data cached in Redis", [
                'location' => $locationQuery,
                'cache_key' => $cacheKey,
                'ttl_minutes' => $this->cacheMinutes,
                'data_timestamp' => $weatherData['_cached_at'] ?? 'unknown'
            ]);

            return response()->json($responseData);

        } catch (\Exception $e) {
            Log::error('Weather fetch failed: ' . $e->getMessage(), [
                'exception' => $e,
                'location' => $locationQuery ?? null,
                'stack_trace' => $e->getTraceAsString()
            ]);
            
            return response()->json([
                'location' => [],
                'current' => [],
                'forecast' => ['forecastday' => []],
                'alerts' => ['alert' => []],
                'error' => 'Failed to fetch weather data',
                'message' => app()->environment('production') ? 'Service temporarily unavailable' : $e->getMessage()
            ], 503);
        }
    }

    /**
     * Clear weather cache for a specific location (for testing/debugging)
     */
    public function clearCache(Request $request)
    {
        try {
            $validated = $request->validate([
                'q' => 'required|string',
                'days' => 'integer|between:1,10',
                'alerts' => 'string|in:yes,no'
            ]);

            $locationQuery = $validated['q'];
            $days = $validated['days'] ?? 3;
            $alerts = $validated['alerts'] ?? 'yes';

            $cacheKey = $this->generateCacheKey($locationQuery, $days, $alerts);
            $cleared = Cache::forget($cacheKey);

            return response()->json([
                'success' => true,
                'message' => 'Cache cleared',
                'cache_key' => $cacheKey,
                'was_cached' => $cleared
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to clear cache: ' . $e->getMessage()
            ], 500);
        }
    }
}
