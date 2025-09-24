<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateStockVolumesTable extends Migration
{
    public function up()
    {
        Schema::create('stock_volumes', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('shop_id');
            $table->string('stock_ids')->comment('Comma-separated stock IDs');
            $table->integer('volume')->comment('Volume in liters');
            $table->timestamps();

            $table->foreign('shop_id')->references('id')->on('shops')->onDelete('cascade');
            $table->unique(['shop_id', 'stock_ids']);
        });
    }

    public function down()
    {
        Schema::dropIfExists('stock_volumes');
    }
}
