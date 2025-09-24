<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Services\WeatherService\WeatherService;
use App\Models\Weather\WeatherData;

class UpdateWeatherCommand extends Command
{
    protected $signature = 'weather:update';
    protected $description = 'Update weather data for all active locations';

    public function handle()
    {
        $this->info('Starting weather update for all active locations...');

        try {
            $weatherService = app(WeatherService::class);
            
            // Clean up old inactive locations first
            WeatherData::deactivateOldLocations();
            
            // Fetch weather for all active locations
            $results = $weatherService->fetchAllActiveLocations(3, 'yes');
            
            $successful = collect($results)->where('status', 'success')->count();
            $failed = collect($results)->where('status', 'failed')->count();
            
            $this->info("Weather update completed:");
            $this->info("✅ Successful: {$successful}");
            if ($failed > 0) {
                $this->warn("❌ Failed: {$failed}");
            }
            
            // Show details for failed requests
            $failures = collect($results)->where('status', 'failed');
            foreach ($failures as $failure) {
                $this->error("Failed: {$failure['location']} - {$failure['error']}");
            }
            
            return Command::SUCCESS;
            
        } catch (\Exception $e) {
            $this->error("Weather update failed: " . $e->getMessage());
            return Command::FAILURE;
        }
    }
}
