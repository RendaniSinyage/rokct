<?php

namespace App\Console\Commands;

use Illuminate\Foundation\Console\UpCommand as BaseUpCommand;
use Illuminate\Support\Facades\Cache;

class UpCommand extends BaseUpCommand
{
    public function handle()
    {
        Cache::forever('last_maintenance_end', now());
        return parent::handle();
    }
}
