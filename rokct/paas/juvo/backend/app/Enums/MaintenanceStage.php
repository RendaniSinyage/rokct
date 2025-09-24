<?php

namespace App\Enums;

enum MaintenanceStage: string {
    case INITIAL_CHECK = 'initialCheck';
    case PRESSURE_RELEASE = 'pressureRelease';
    case BACKWASH = 'backwash';
    case SETTLING = 'settling';
    case FAST_WASH = 'fastWash';
    case STABILIZATION = 'stabilization';
    case RETURN_TO_FILTER = 'returnToFilter';
    case BRINE_AND_SLOW_RINSE = 'brineAndSlowRinse';
    case FAST_RINSE = 'fastRinse';
    case BRINE_REFILL = 'brineRefill';
    case RETURN_TO_SERVICE = 'returnToService';
}
