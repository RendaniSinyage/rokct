<?php
// Create a migration file for Success Wheel Elements
// database/migrations/YYYY_MM_DD_HHMMSS_create_success_wheel_elements_table.php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateSuccessWheelElementsTable extends Migration
{
    public function up()
    {
        Schema::create('success_wheel_elements', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->unsignedBigInteger('shop_id')->nullable(); // null means it belongs to admin
            $table->string('name', 100);
            $table->enum('category', [
                'Leadership & Vision', 
                'Human Resource', 
                'Technology & Communications', 
                'Operational & Quality Management Systems',
                'Financial Sustainability',
                'Legislation & Compliance',
                'Sales & Marketing',
                'Product or Service',
                'Social & Environmental Impact'
            ]);
            $table->unsignedBigInteger('related_pillar_id');
            $table->text('description')->nullable();
            $table->integer('score')->default(0); // For scoring progress (0-10)
            $table->timestamps();
            $table->softDeletes();
            
            $table->foreign('shop_id')->references('id')->on('shops')->onDelete('cascade');
            $table->foreign('related_pillar_id')->references('id')->on('pillars')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('success_wheel_elements');
    }
}
