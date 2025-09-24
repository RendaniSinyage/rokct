<?php
// Create a migration file for Pillars
// database/migrations/YYYY_MM_DD_HHMMSS_create_pillars_table.php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreatePillarsTable extends Migration
{
    public function up()
    {
        Schema::create('pillars', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->unsignedBigInteger('shop_id')->nullable(); // null means it belongs to admin
            $table->unsignedBigInteger('vision_id');
            $table->string('name', 100);
            $table->text('description')->nullable();
            $table->string('icon', 50)->nullable();
            $table->string('color', 20)->nullable();
            $table->unsignedInteger('display_order')->default(0);
            $table->timestamps();
            $table->softDeletes();
            
            $table->foreign('shop_id')->references('id')->on('shops')->onDelete('cascade');
            $table->foreign('vision_id')->references('id')->on('visions')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('pillars');
    }
}


