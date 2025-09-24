<?php

namespace App\Helpers;

use Carbon\Carbon;

class TimezoneHelper
{
    /**
     * Convert a datetime to the application timezone
     *
     * @param string|Carbon $datetime
     * @return Carbon
     */
    public static function convertToAppTimezone($datetime): Carbon
    {
        $appTimezone = config('app.timezone', 'UTC');
        
        // If it's already a Carbon instance, just change the timezone
        if ($datetime instanceof Carbon) {
            return $datetime->setTimezone($appTimezone);
        }
        
        // If it's a string, parse it and set to app timezone
        return Carbon::parse($datetime)->setTimezone($appTimezone);
    }

    /**
     * Format datetime in the application timezone
     *
     * @param string|Carbon $datetime
     * @param string $format
     * @return string
     */
    public static function formatInAppTimezone($datetime, string $format = 'Y-m-d H:i:s'): string
    {
        return self::convertToAppTimezone($datetime)->format($format);
    }
}
