<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\MeterReading;

class MeterReadingsTableSeeder extends Seeder
{
    public function run()
    {
        MeterReading::create([
            'meterId' => '12345',
            'reading' => 100,
            'timestamp' => '2024-09-10 12:34:56',
            'userId' => 'user01',
            'shopId' => 1,
            'imagePath' => '/path/to/image1.jpg',
        ]);

        // Add more test data as needed
    }
}
