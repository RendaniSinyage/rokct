<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateRoSystemsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up(): void
{
    Schema::create('ro_systems', function (Blueprint $table) {
        $table->id();
        $table->foreignId('shop_id')->constrained()->onDelete('cascade');
        $table->integer('membrane_count');
        $table->timestamp('membrane_installation_date');
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
        Schema::dropIfExists('ro_systems');
    }
}

