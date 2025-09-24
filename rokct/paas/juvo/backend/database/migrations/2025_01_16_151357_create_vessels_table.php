<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateVesselsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up(): void
{
    Schema::create('vessels', function (Blueprint $table) {
        $table->id();
        $table->foreignId('ro_system_id')->constrained()->onDelete('cascade');
        $table->string('external_id')->unique(); // e.g., 'megaChar_1'
        $table->enum('type', ['megaChar', 'softener']);
        $table->timestamp('installation_date');
        $table->timestamp('last_maintenance_date')->nullable();
        $table->enum('current_stage', [
            'initialCheck', 'pressureRelease', 'backwash', 
            'settling', 'fastWash', 'brineAndSlowRinse', 
            'fastRinse', 'brineRefill', 'stabilization', 
            'returnToService', 'returnToFilter'
        ])->nullable();
        $table->timestamp('maintenance_start_time')->nullable();
        $table->timestamps();
    });
}

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('vessels');
    }
}

