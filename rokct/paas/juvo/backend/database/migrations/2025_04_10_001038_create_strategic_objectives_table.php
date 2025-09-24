<?php
// Create a migration file for Strategic Objectives
// database/migrations/YYYY_MM_DD_HHMMSS_create_strategic_objectives_table.php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateStrategicObjectivesTable extends Migration
{
    public function up()
    {
        Schema::create('strategic_objectives', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->unsignedBigInteger('shop_id')->nullable(); // null means it belongs to admin
            $table->unsignedBigInteger('pillar_id');
            $table->string('title', 255);
            $table->text('description')->nullable();
            $table->boolean('is_90_day_priority')->default(false);
            $table->enum('time_horizon', ['Short-term', 'Medium-term', 'Long-term'])->default('Short-term');
            $table->enum('status', ['Not Started', 'In Progress', 'Completed', 'Deferred'])->default('Not Started');
            $table->date('start_date')->nullable();
            $table->date('target_date')->nullable();
            $table->date('completion_date')->nullable();
            $table->timestamps();
            $table->softDeletes();
            
            $table->foreign('shop_id')->references('id')->on('shops')->onDelete('cascade');
            $table->foreign('pillar_id')->references('id')->on('pillars')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('strategic_objectives');
    }
}


