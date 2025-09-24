<?php

namespace App\Services\WeatherService;

use App\Models\Weather\WeatherData;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

class WeatherService
{
    protected $baseUrl = 'http://api.weatherapi.com/v1/forecast.json';
    protected $apiKey;
    protected $maxRetries = 3;
    protected $retryDelay = 1; // seconds
    protected $retryableStatusCodes = [502, 503, 504];

    public function __construct()
    {
        $this->apiKey = config('services.weatherapi.key');
    }

    /**
     * Get weather data - serves from Redis cache or fetches fresh
     */
    public function getWeatherData($location, $days = 3, $alerts = 'yes')
    {
        [$cityName, $countryCode] = $this->parseLocation($location);
        
        try {
            if (!$this->apiKey) {
                throw new \Exception('Weather API key is not configured');
            }

            // Track this location in database (but don't store weather data)
            $locationRecord = WeatherData::trackLocation($cityName, $countryCode);
            
            // Try to get from Redis cache first
            $cacheKey = $locationRecord->getCacheKey($days, $alerts);
            $cachedData = Cache::get($cacheKey);
            
            if ($cachedData) {
                Log::info("Serving cached weather data for {$locationRecord->getLocationString()}");
                return $cachedData;
            }

            // If not in cache, fetch fresh data
            Log::info("Fetching fresh weather data for {$locationRecord->getLocationString()}");
            $weatherData = $this->fetchFromApiWithRetry($locationRecord->getLocationString(), $days, $alerts);
            
            // Store in Redis cache (3 hours TTL)
            $this->cacheWeatherData($cacheKey, $weatherData, 180); // 3 hours
            
            // Mark location as fetched
            $locationRecord->markAsFetched();
            
            return $weatherData;

        } catch (\Exception $e) {
            Log::error("Weather fetch failed for {$cityName},{$countryCode}", [
                'error' => $e->getMessage(),
                'api_key_present' => (bool)$this->apiKey
            ]);

            throw $e;
        }
    }

    /**
     * Fetch weather data for all active locations (used by scheduler)
     */
    public function fetchAllActiveLocations($days = 3, $alerts = 'yes')
    {
        $locations = WeatherData::getActiveLocations();
        $results = [];
        
        Log::info("Fetching weather for " . $locations->count() . " active locations");

        foreach ($locations as $location) {
            try {
                $cacheKey = $location->getCacheKey($days, $alerts);
                $weatherData = $this->fetchFromApiWithRetry($location->getLocationString(), $days, $alerts);
                
                // Store in Redis cache (3 hours TTL)
                $this->cacheWeatherData($cacheKey, $weatherData, 180);
                
                // Mark as fetched
                $location->markAsFetched();
                
                $results[] = [
                    'location' => $location->getLocationString(),
                    'status' => 'success',
                    'cached_at' => now()->toDateTimeString()
                ];
                
                Log::info("Successfully fetched weather for {$location->getLocationString()}");
                
                // Small delay between API calls to be nice to the API
                usleep(500000); // 0.5 seconds
                
            } catch (\Exception $e) {
                $results[] = [
                    'location' => $location->getLocationString(),
                    'status' => 'failed',
                    'error' => $e->getMessage()
                ];
                
                Log::error("Failed to fetch weather for {$location->getLocationString()}", [
                    'error' => $e->getMessage()
                ]);
            }
        }

        return $results;
    }

    /**
     * Cache weather data in Redis
     */
    protected function cacheWeatherData($cacheKey, $weatherData, $minutes)
    {
        $weatherData['_cached_at'] = now()->toDateTimeString();
        Cache::put($cacheKey, $weatherData, now()->addMinutes($minutes));
        
        Log::debug("Weather data cached", [
            'cache_key' => $cacheKey,
            'ttl_minutes' => $minutes
        ]);
    }

    /**
     * Fetch from API with retry logic
     */
    protected function fetchFromApiWithRetry($location, $days, $alerts)
    {
        $attempts = 0;
        $lastException = null;

        while ($attempts < $this->maxRetries) {
            try {
                return $this->fetchFromApi($location, $days, $alerts);
            } catch (\Exception $e) {
                $lastException = $e;
                $attempts++;

                // Get status code from exception if it's a HTTP exception
                $statusCode = $e->getCode();
                if (method_exists($e, 'response') && $e->response) {
                    $statusCode = $e->response->status();
                }

                // Only retry on specific status codes
                if (!in_array($statusCode, $this->retryableStatusCodes)) {
                    throw $e;
                }

                Log::warning("Weather API attempt {$attempts} failed for {$location}", [
                    'error' => $e->getMessage(),
                    'status_code' => $statusCode
                ]);
                
                if ($attempts < $this->maxRetries) {
                    $delay = $this->retryDelay * pow(2, $attempts - 1); // Exponential backoff
                    sleep($delay);
                }
            }
        }

        throw $lastException;
    }

    /**
     * Fetch from API
     */
    protected function fetchFromApi($location, $days, $alerts)
    {
        $response = Http::withOptions([
            'verify' => false,
            'timeout' => 15,
        ])->get($this->baseUrl, [
            'key' => $this->apiKey,
            'q' => $location,
            'days' => $days,
            'alerts' => $alerts
        ]);

        if (!$response->successful()) {
            Log::error('Weather API request failed', [
                'status' => $response->status(),
                'body' => $response->body(),
                'location' => $location
            ]);
            throw new \Exception('Weather API request failed: ' . $response->status(), $response->status());
        }

        return $response->json();
    }

    /**
     * Parse location string
     */
    protected function parseLocation($location)
    {
        $parts = explode(',', strtolower($location));
        return [
            trim($parts[0]),
            trim($parts[1] ?? '')
        ];
    }
}
