<?php
// Create a migration file for Company Values
// database/migrations/YYYY_MM_DD_HHMMSS_create_company_values_table.php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateCompanyValuesTable extends Migration
{
    public function up()
    {
        Schema::create('company_values', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->unsignedBigInteger('shop_id')->nullable(); // null means it belongs to admin
            $table->string('name', 100);
            $table->text('description')->nullable();
            $table->text('action_items')->nullable(); // How the value is implemented
            $table->timestamps();
            $table->softDeletes();
            
            $table->foreign('shop_id')->references('id')->on('shops')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('company_values');
    }
}


