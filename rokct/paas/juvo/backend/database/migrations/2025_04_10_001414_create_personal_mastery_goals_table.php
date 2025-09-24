<?php
// Create a migration file for Personal Mastery Goals
// database/migrations/YYYY_MM_DD_HHMMSS_create_personal_mastery_goals_table.php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreatePersonalMasteryGoalsTable extends Migration
{
    public function up()
    {
        Schema::create('personal_mastery_goals', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->unsignedBigInteger('user_id');
            $table->enum('area', [
                'Financial', 
                'Vocation/Work', 
                'Family', 
                'Friends', 
                'Spiritual', 
                'Physical', 
                'Learning & Skills'
            ]);
            $table->string('title', 255);
            $table->text('description')->nullable();
            $table->unsignedBigInteger('related_objective_id')->nullable(); // Can be linked to a strategic objective
            $table->date('target_date')->nullable();
            $table->enum('status', ['Not Started', 'In Progress', 'Completed'])->default('Not Started');
            $table->timestamps();
            $table->softDeletes();
            
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('related_objective_id')->references('id')->on('strategic_objectives')->onDelete('set null');
        });
    }

    public function down()
    {
        Schema::dropIfExists('personal_mastery_goals');
    }
}


