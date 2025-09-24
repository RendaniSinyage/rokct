<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::table('weather_data', function (Blueprint $table) {
            // Remove the weather_data JSON column since we're storing it in Redis
            $table->dropColumn('weather_data');
            
            // Add unique constraint to prevent duplicate locations
            $table->unique(['city_name', 'country_code']);
        });
    }

    public function down()
    {
        Schema::table('weather_data', function (Blueprint $table) {
            // Re-add the weather_data column
            $table->json('weather_data')->nullable();
            
            // Drop the unique constraint
            $table->dropUnique(['city_name', 'country_code']);
        });
    }
};
