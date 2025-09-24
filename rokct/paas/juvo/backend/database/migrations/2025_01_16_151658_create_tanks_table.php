<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateTanksTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up(): void
{
    Schema::create('tanks', function (Blueprint $table) {
        $table->id();
        $table->foreignId('shop_id')->constrained()->onDelete('cascade');
        $table->string('number');
        $table->enum('type', ['raw', 'purified']);
        $table->decimal('capacity', 10, 2); // in liters
        $table->enum('status', ['full', 'empty', 'halfEmpty', 'quarterEmpty']);
        $table->json('pump_status');
        $table->json('water_quality');
        $table->timestamp('last_full')->nullable();
        $table->timestamps();
        
        // Ensure number is unique per shop and type
        $table->unique(['shop_id', 'type', 'number']);
    });
}

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('tanks');
    }
}

