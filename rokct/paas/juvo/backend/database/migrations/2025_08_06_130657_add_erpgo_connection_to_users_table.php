<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddErpgoConnectionToUsersTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('users', function (Blueprint $table) {
            // ERPGo integration fields
            $table->boolean('erpgo_connected')->default(false)->after('active')->comment('Whether user is connected to ERPGo business management');
            $table->string('erpgo_user_id')->nullable()->after('erpgo_connected')->comment('User ID in ERPGo system');
            $table->timestamp('erpgo_connected_at')->nullable()->after('erpgo_user_id')->comment('When ERPGo connection was established');
            $table->string('erpgo_access_token')->nullable()->after('erpgo_connected_at')->comment('ERPGo OAuth access token');
            $table->string('erpgo_refresh_token')->nullable()->after('erpgo_access_token')->comment('ERPGo OAuth refresh token');
            $table->timestamp('erpgo_token_expires_at')->nullable()->after('erpgo_refresh_token')->comment('When ERPGo access token expires');
            
            // Add indexes for better performance
            $table->index(['erpgo_connected', 'erpgo_user_id'], 'erpgo_connection_idx');
            $table->index(['email', 'erpgo_connected'], 'email_erpgo_idx');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('users', function (Blueprint $table) {
            // Drop indexes first
            $table->dropIndex('erpgo_connection_idx');
            $table->dropIndex('email_erpgo_idx');
            
            // Drop columns
            $table->dropColumn([
                'erpgo_connected',
                'erpgo_user_id', 
                'erpgo_connected_at',
                'erpgo_access_token',
                'erpgo_refresh_token',
                'erpgo_token_expires_at'
            ]);
        });
    }
};
