<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Date;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     *
     * @return void
     */
    public function register(): void
    {
        // If you want to re-enable Telescope, you can uncomment these lines
        // if ($this->app->environment('local')) {
        //     $this->app->register(\Laravel\Telescope\TelescopeServiceProvider::class);
        //     $this->app->register(TelescopeServiceProvider::class);
        // }
    }
    
    /**
     * Bootstrap any application services.
     *
     * @return void
     */
    public function boot(): void
    {
        // Set PHP timezone
        date_default_timezone_set('Africa/Johannesburg');
        
        // Configure date serialization to always use SA timezone
        Date::serializeUsing(function ($date) {
            return $date
                ->clone()
                ->setTimezone('Africa/Johannesburg')
                ->format('Y-m-d H:i:s');
        });
        
        Cache::forever('last_restart', now());
    }
}
