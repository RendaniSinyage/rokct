<?php
// Create a migration file for Todo Tasks
// database/migrations/YYYY_MM_DD_HHMMSS_create_todo_tasks_table.php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateTodoTasksTable extends Migration
{
    public function up()
    {
        Schema::create('todo_tasks', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->unsignedBigInteger('shop_id')->nullable(); // null means it belongs to admin
            $table->unsignedBigInteger('kpi_id')->nullable(); // Can be linked to a KPI, but not required
            $table->unsignedBigInteger('objective_id')->nullable(); // Can be linked directly to objective
            $table->string('title', 255);
            $table->text('description')->nullable();
            $table->date('due_date')->nullable();
            $table->unsignedBigInteger('assigned_to')->nullable();
            $table->enum('status', ['Todo', 'In Progress', 'Done', 'Blocked'])->default('Todo');
            $table->enum('priority', ['Low', 'Medium', 'High', 'Urgent'])->default('Medium');
            $table->unsignedBigInteger('app_id')->nullable(); // Can be linked to a specific app
            $table->string('roadmap_version', 50)->nullable(); // For app-related tasks
            $table->timestamps();
            $table->softDeletes();
            
            $table->foreign('shop_id')->references('id')->on('shops')->onDelete('cascade');
            $table->foreign('kpi_id')->references('id')->on('kpis')->onDelete('set null');
            $table->foreign('objective_id')->references('id')->on('strategic_objectives')->onDelete('set null');
            // foreign key for assigned_to and app_id would need to reference their respective tables
        });
    }

    public function down()
    {
        Schema::dropIfExists('todo_tasks');
    }
}


