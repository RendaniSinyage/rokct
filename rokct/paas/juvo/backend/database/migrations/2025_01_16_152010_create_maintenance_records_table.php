<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateMaintenanceRecordsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up(): void
{
    Schema::create('maintenance_records', function (Blueprint $table) {
        $table->id();
        $table->foreignId('shop_id')->constrained()->onDelete('cascade');
        $table->enum('type', ['vessel', 'membrane', 'filter']);
        $table->string('reference_id'); // e.g., 'megaChar_1', 'filter_1'
        $table->timestamp('maintenance_date');
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
        Schema::dropIfExists('maintenance_records');
    }
}

