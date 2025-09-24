<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddPlatformsToTodoTasks extends Migration
{
    public function up()
    {
        Schema::table('todo_tasks', function (Blueprint $table) {
            $table->json('platforms')->nullable();
        });
    }

    public function down()
    {
        Schema::table('todo_tasks', function (Blueprint $table) {
            $table->dropColumn('platforms');
        });
    }
}
