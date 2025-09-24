<?php

namespace App\Enums;

enum TankStatus: string
{
    case Full = 'full';
    case Empty = 'empty';
    case HalfEmpty = 'halfEmpty';
    case QuarterEmpty = 'quarterEmpty';
}
