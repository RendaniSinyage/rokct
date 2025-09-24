<?php
// Create a migration file for Apps
// database/migrations/YYYY_MM_DD_HHMMSS_create_apps_table.php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateAppsTable extends Migration
{
    public function up()
{
    Schema::dropIfExists('apps');
    Schema::create('apps', function (Blueprint $table) {
        $table->id();
        $table->uuid('uuid')->unique();
        $table->unsignedBigInteger('shop_id')->nullable();
        $table->string('name', 100);
        $table->string('package_name', 100)->nullable();
        $table->text('description')->nullable();
        $table->enum('platform', ['iOS', 'Android', 'Web', 'Cross-Platform'])->default('Cross-Platform');
        $table->string('icon', 255)->nullable();
        $table->string('current_version', 50)->nullable();
        $table->timestamps();
        $table->softDeletes();
        
        $table->foreign('shop_id')->references('id')->on('shops')->onDelete('cascade');
    });
}

    public function down()
    {
        Schema::dropIfExists('apps');
    }
}
