<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateLoanApplicationsTable extends Migration
{
    public function up()
    {
        Schema::create('loan_applications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->string('id_number')->nullable();
            $table->decimal('amount', 10, 2);
            $table->enum('status', [
                'incomplete', 
                'pending_review', 
                'pending_contract', 
                'pending_disbursal', 
                'active', 
                'rejected', 
                'paid_off', 
                'overdue',
                'cancelled'
            ])->default('incomplete');
            $table->json('documents')->nullable();
            $table->json('additional_data')->nullable();
            $table->timestamp('contract_accepted_at')->nullable();
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('loan_applications');
    }
}
