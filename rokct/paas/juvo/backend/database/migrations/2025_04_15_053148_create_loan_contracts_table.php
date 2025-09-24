<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateLoanContractsTable extends Migration
{
    public function up()
    {
        Schema::create('loan_contracts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('loan_application_id')
                  ->constrained('loan_applications')
                  ->onDelete('cascade');
            
            $table->string('title');
            $table->text('content');
            
            $table->enum('status', [
                'pending_acceptance', 
                'accepted', 
                'declined', 
                'expired'
            ])->default('pending_acceptance');
            
            $table->timestamp('accepted_at')->nullable();
            $table->timestamp('declined_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            
            $table->decimal('interest_rate', 5, 2)->nullable();
            $table->integer('loan_term_months')->nullable();
            
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('loan_contracts');
    }
}
