<?php

namespace App\Console;

use App\Models\Settings;
use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{

 /**
     * The Artisan commands provided by your application.
     *
     * @var array
     */
    protected $commands = [
        Commands\DownCommand::class,
        Commands\UpCommand::class,
    ];

	/**
	 * Define the application's command schedule.
	 *
	 * @param Schedule $schedule
	 * @return void
	 */
	protected function schedule(Schedule $schedule): void
	{
//		$schedule->command('sudo chmod -R 777 ./storage/')->hourly();
//		$schedule->command('sudo chmod -R 777 ./bootstrap/cache/')->hourly();
		$schedule->command('email:send:by:time')->hourly();
		$schedule->command('remove:expired:bonus:from:cart')->dailyAt('00:01');
		$schedule->command('remove:expired:closed:dates')->dailyAt('00:01');
		$schedule->command('remove:expired:stories')->dailyAt('00:01');
		$schedule->command('order:auto:repeat')->dailyAt('00:01');
		$schedule->command('expired:subscription:remove')->everyMinute();
//        	 $schedule->command('truncate:telescope')->daily();
		$schedule->command('update:models:galleries')->hourly()->withoutOverlapping()->runInBackground();
		$schedule->command('weather:fetch')->everyThreeHours()->startingAt('0:05');
		$schedule->command('weather:cleanup')->daily();
// Update weather every 3 hours at specific times
   		 $schedule->command('weather:update')
             ->cron('0 1,4,7,10,13,16,19,22 * * *')
             ->withoutOverlapping()
             ->runInBackground();

// Daily cleanup of documents from rejected/cancelled applications
       	 $schedule->command('loans:cleanup-documents --force')
            ->daily()
            ->at('02:00') // Run at 2 AM
            ->appendOutputTo(storage_path('logs/loan-document-cleanup.log'));
	}

	/**
	 * Register the commands for the application.
	 *
	 * @return void
	 */
	protected function commands(): void
	{
		$this->load(__DIR__.'/Commands');

		require base_path('routes/console.php');
	}
}

