<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('deliveryman_settings', function (Blueprint $table) {
            $table->integer('height')->nullable()->after('color');
            $table->integer('width')->nullable()->after('height');
            $table->integer('length')->nullable()->after('width');
            $table->integer('kg')->nullable()->after('length');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('deliveryman_settings', function (Blueprint $table) {
            $table->dropColumn(['height', 'width', 'length', 'kg']);
        });
    }
};
