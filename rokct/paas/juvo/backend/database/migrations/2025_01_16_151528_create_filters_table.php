<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateFiltersTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up(): void
{
    Schema::create('filters', function (Blueprint $table) {
        $table->id();
        $table->foreignId('ro_system_id')->constrained()->onDelete('cascade');
        $table->string('external_id')->unique(); // e.g., 'filter_1'
        $table->enum('type', ['birm', 'sediment', 'carbonBlock']);
        $table->enum('location', ['pre', 'ro', 'post']);
        $table->timestamp('installation_date');
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
        Schema::dropIfExists('filters');
    }
}

