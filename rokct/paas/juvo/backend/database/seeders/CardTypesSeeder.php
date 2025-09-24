<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CardTypesSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        $cardTypes = [
            ['name' => 'Visa', 'code' => 'visa'],
            ['name' => 'Mastercard', 'code' => 'mastercard'],
            ['name' => 'American Express', 'code' => 'amex'],
            ['name' => 'Discover', 'code' => 'discover'],
            ['name' => 'Diners Club', 'code' => 'diners'],
            // Add more card types as needed
        ];

        // Insert card types, avoiding duplicates
        foreach ($cardTypes as $cardType) {
            DB::table('card_types')->updateOrInsert(
                ['code' => $cardType['code']],
                $cardType
            );
        }
    }
}
