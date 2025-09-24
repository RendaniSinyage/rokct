<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateAppUsagesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('app_usages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->date('usage_date');
            $table->year('year');
            $table->string('platform')->nullable();
            $table->string('app_version')->nullable();
            $table->string('build_number')->nullable();
            $table->timestamps();
            
            // Add a unique index to prevent duplicate records for the same day
            $table->unique(['user_id', 'usage_date']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('app_usages');
    }
}
