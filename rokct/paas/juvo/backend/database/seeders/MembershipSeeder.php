<?php

namespace Database\Seeders;

use App\Models\Membership;
use Illuminate\Database\Seeder;

class MembershipSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        $memberships = [
            [
                'title' => 'Basic Plan',
                'type' => 'monthly',
                'price' => 9.99,
                'duration' => 30,
                'duration_unit' => 'days',
                'description' => 'Basic membership with standard features',
                'is_active' => true,
            ],
            [
                'title' => 'Premium Plan',
                'type' => 'monthly',
                'price' => 19.99,
                'duration' => 30,
                'duration_unit' => 'days',
                'description' => 'Premium membership with advanced features',
                'is_active' => true,
            ],
            [
                'title' => 'Gold Plan',
                'type' => 'yearly',
                'price' => 99.99,
                'duration' => 365,
                'duration_unit' => 'days',
                'description' => 'Gold membership with all features and benefits',
                'is_active' => true,
            ],
        ];
        
        foreach ($memberships as $membership) {
            Membership::create($membership);
        }
    }
}
