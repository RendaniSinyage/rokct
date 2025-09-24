<?php
// Create a migration file for Roadmap Versions
// database/migrations/YYYY_MM_DD_HHMMSS_create_roadmap_versions_table.php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateRoadmapVersionsTable extends Migration
{
    public function up()
    {
        Schema::create('roadmap_versions', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->unsignedBigInteger('app_id');
            $table->string('version_number', 50);
            $table->enum('status', ['Planning', 'Development', 'Testing', 'Released'])->default('Planning');
            $table->text('description')->nullable();
            $table->json('features')->nullable(); // Store features as a JSON array
            $table->date('release_date')->nullable();
            $table->timestamps();
            $table->softDeletes();
            
            $table->foreign('app_id')->references('id')->on('apps')->onDelete('cascade');
            
            // Ensure version numbers are unique per app
            $table->unique(['app_id', 'version_number']);
        });
    }

    public function down()
    {
        Schema::dropIfExists('roadmap_versions');
    }
}


