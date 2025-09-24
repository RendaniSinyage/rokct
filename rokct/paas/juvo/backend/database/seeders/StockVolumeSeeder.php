<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\StockVolume;
use App\Models\Shop;

class StockVolumeSeeder extends Seeder
{
    public function run()
    {
        // Assuming 9003 is the shop ID
        $shopId = 9003;

        $stockVolumes = [
            ['672, 295, 303', 25],
            ['671, 293, 301', 20],
            ['670, 291, 299', 10],
            ['669, 281, 297, 298', 5],
            ['668', 3],
        ];

        foreach ($stockVolumes as $volumeData) {
            StockVolume::firstOrCreate([
                'shop_id' => $shopId,
                'stock_ids' => $volumeData[0],
                'volume' => $volumeData[1]
            ]);
        }
    }
}
