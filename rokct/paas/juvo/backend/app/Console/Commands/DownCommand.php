<?php

namespace App\Console\Commands;

use Illuminate\Foundation\Console\DownCommand as BaseDownCommand;
use Illuminate\Support\Facades\Cache;

class DownCommand extends BaseDownCommand
{
    protected $signature = 'down {--message= : The message for the maintenance mode}
                 {--retry= : The number of seconds after which the request may be retried}
                 {--refresh= : The number of seconds before the maintenance mode message is refreshed}
                 {--secret= : The secret phrase that allows maintenance mode to be bypassed}
                 {--status=503 : The status code the server will use}';

    public function handle()
    {
        Cache::forever('last_maintenance_start', now());
        return parent::handle();
    }
}
