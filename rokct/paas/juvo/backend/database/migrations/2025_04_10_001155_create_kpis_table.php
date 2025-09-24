<?php
// Create a migration file for KPIs
// database/migrations/YYYY_MM_DD_HHMMSS_create_kpis_table.php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateKpisTable extends Migration
{
    public function up()
    {
        Schema::create('kpis', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->unsignedBigInteger('shop_id')->nullable(); // null means it belongs to admin
            $table->unsignedBigInteger('objective_id');
            $table->string('metric', 255);
            $table->string('target_value', 100)->nullable();
            $table->string('current_value', 100)->nullable();
            $table->string('unit', 50)->nullable();
            $table->date('due_date');
            $table->enum('status', ['Not Started', 'In Progress', 'Completed', 'Overdue'])->default('Not Started');
            $table->date('completion_date')->nullable();
            $table->timestamps();
            $table->softDeletes();
            
            $table->foreign('shop_id')->references('id')->on('shops')->onDelete('cascade');
            $table->foreign('objective_id')->references('id')->on('strategic_objectives')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('kpis');
    }
}


