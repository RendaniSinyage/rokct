<?php
// Create a migration file for Business Projections
// database/migrations/YYYY_MM_DD_HHMMSS_create_business_projections_table.php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateBusinessProjectionsTable extends Migration
{
    public function up()
    {
        Schema::create('business_projections', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->unsignedBigInteger('shop_id')->nullable(); // null means it belongs to admin
            $table->string('year', 10);
            $table->decimal('sales_projection', 15, 2)->nullable();
            $table->integer('jobs_projection')->nullable();
            $table->string('other_metric_name', 100)->nullable();
            $table->string('other_metric_value', 100)->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->softDeletes();
            
            $table->foreign('shop_id')->references('id')->on('shops')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('business_projections');
    }
}


