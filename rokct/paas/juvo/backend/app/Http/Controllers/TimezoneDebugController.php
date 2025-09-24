<?php

namespace App\Http\Controllers;

use Illuminate\Routing\Controller;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use App\Providers\TimezoneServiceProvider;

class TimezoneDebugController extends Controller
{
    public function checkTimezones(): JsonResponse
    {
        // Force timezone conversion
        $nowInAppTimezone = TimezoneServiceProvider::convertToAppTimezone(Carbon::now());

        return response()->json([
            'original_php_time' => date('Y-m-d H:i:s'),
            'original_laravel_time' => now()->toDateTimeString(),
            'app_timezone' => config('app.timezone'),
            'php_default_timezone' => date_default_timezone_get(),
            'converted_time' => $nowInAppTimezone->toDateTimeString(),
            'converted_timezone' => $nowInAppTimezone->timezone->getName(),
            'utc_time' => Carbon::now('UTC')->toDateTimeString()
        ]);
    }
}
