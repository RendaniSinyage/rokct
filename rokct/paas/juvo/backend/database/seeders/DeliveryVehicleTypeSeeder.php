<?php
// database/seeders/DeliveryVehicleTypeSeeder.php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DeliveryVehicleTypeSeeder extends Seeder
{
    public function run()
    {
        $vehicleTypes = [
            [
                'key' => 'foot',
                'name' => 'On Foot',
                'description' => 'Walking delivery for very local orders',
                'active' => true,
                'sort_order' => 1,
                'max_weight_kg' => 5,
                'base_rate' => 10.00,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'key' => 'bike',
                'name' => 'Bicycle',
                'description' => 'Bicycle delivery for local orders',
                'active' => true,
                'sort_order' => 2,
                'max_weight_kg' => 10,
                'base_rate' => 15.00,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'key' => 'motorbike',
                'name' => 'Motorbike',
                'description' => 'Motorbike delivery for standard orders',
                'active' => true,
                'sort_order' => 3,
                'max_weight_kg' => 20,
                'base_rate' => 25.00,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'key' => 'benzine',
                'name' => 'Car (Petrol)',
                'description' => 'Petrol car for medium distance delivery',
                'active' => true,
                'sort_order' => 4,
                'max_weight_kg' => 50,
                'base_rate' => 35.00,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'key' => 'electric',
                'name' => 'Electric Vehicle',
                'description' => 'Electric car for eco-friendly delivery',
                'active' => true,
                'sort_order' => 5,
                'max_weight_kg' => 50,
                'base_rate' => 30.00,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'key' => 'hybrid',
                'name' => 'Hybrid Vehicle',
                'description' => 'Hybrid car for efficient delivery',
                'active' => true,
                'sort_order' => 6,
                'max_weight_kg' => 50,
                'base_rate' => 32.00,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'key' => 'diesel',
                'name' => 'Car (Diesel)',
                'description' => 'Diesel car for long distance delivery',
                'active' => true,
                'sort_order' => 7,
                'max_weight_kg' => 60,
                'base_rate' => 40.00,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'key' => 'gas',
                'name' => 'Gas Vehicle',
                'description' => 'Gas-powered vehicle for delivery',
                'active' => true,
                'sort_order' => 8,
                'max_weight_kg' => 50,
                'base_rate' => 35.00,
                'created_at' => now(),
                'updated_at' => now()
            ],
            // NEW AGRICULTURAL VEHICLE TYPES
            [
                'key' => 'bakkie',
                'name' => 'Bakkie/Pickup',
                'description' => 'Small truck for medium agricultural loads',
                'active' => true,
                'sort_order' => 9,
                'max_weight_kg' => 500,
                'base_rate' => 100.00,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'key' => 'truck_small',
                'name' => 'Small Truck',
                'description' => 'Small truck for agricultural bulk delivery',
                'active' => true,
                'sort_order' => 10,
                'max_weight_kg' => 1000,
                'base_rate' => 200.00,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'key' => 'truck_medium',
                'name' => 'Medium Truck',
                'description' => 'Medium truck for large agricultural orders',
                'active' => true,
                'sort_order' => 11,
                'max_weight_kg' => 3000,
                'base_rate' => 350.00,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'key' => 'truck_large',
                'name' => 'Large Truck',
                'description' => 'Large truck for bulk wholesale orders',
                'active' => true,
                'sort_order' => 12,
                'max_weight_kg' => 8000,
                'base_rate' => 500.00,
                'created_at' => now(),
                'updated_at' => now()
            ]
        ];

        DB::table('delivery_vehicle_types')->insert($vehicleTypes);
    }
}
