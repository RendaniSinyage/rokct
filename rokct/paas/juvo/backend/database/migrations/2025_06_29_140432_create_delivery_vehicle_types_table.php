<?php
// database/migrations/create_delivery_vehicle_types_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('delivery_vehicle_types', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique(); // 'motorbike', 'truck', etc.
            $table->string('name'); // Display name
            $table->text('description')->nullable();
            $table->boolean('active')->default(true);
            $table->integer('sort_order')->default(0);
            $table->integer('max_weight_kg')->nullable(); // Max carrying capacity
            $table->decimal('base_rate', 8, 2)->nullable(); // Base delivery rate
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('delivery_vehicle_types');
    }
};
