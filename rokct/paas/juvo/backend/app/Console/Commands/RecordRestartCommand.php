<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Cache;

class RecordRestartCommand extends Command
{
    protected $signature = 'app:record-restart';
    protected $description = 'Record the time of application restart';

    public function handle()
    {
        Cache::forever('last_restart', now());
        $this->info('Application restart time recorded.');
    }
}
