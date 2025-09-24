<?php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

class CreateComboProductsTable extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('combos')) {
            Schema::create('combos', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('shop_id');
                $table->string('img')->nullable();
                $table->boolean('active')->index();
                $table->dateTime('expired_at')->index();
                $table->timestamps();
            });
        }

        if (!Schema::hasTable('combo_translations')) {
            Schema::create('combo_translations', function (Blueprint $table) {
                $table->id();
                $table->foreignId('combo_id')->constrained()->cascadeOnUpdate()->cascadeOnDelete();
                $table->string('locale')->index();
                $table->string('title')->index();
                $table->text('description')->nullable();
            });
        }

        if (!Schema::hasTable('combo_stocks')) {
            Schema::create('combo_stocks', function (Blueprint $table) {
                $table->foreignId('combo_id')->constrained()->cascadeOnUpdate()->cascadeOnDelete();
                $table->foreignId('stock_id')->constrained()->cascadeOnUpdate()->cascadeOnDelete();
            });
        }

        // Only add combo_id if it doesn't exist
        if (!Schema::hasColumn('order_details', 'combo_id')) {
            Schema::table('order_details', function (Blueprint $table) {
                $table->foreignId('combo_id')->constrained()->cascadeOnUpdate()->cascadeOnDelete();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('order_details', 'combo_id')) {
            Schema::table('order_details', function (Blueprint $table) {
                $table->dropForeign(['combo_id']);
                $table->dropColumn('combo_id');
            });
        }
        Schema::dropIfExists('combo_translations');
        Schema::dropIfExists('combo_stocks');
        Schema::dropIfExists('combos');
    }
}
