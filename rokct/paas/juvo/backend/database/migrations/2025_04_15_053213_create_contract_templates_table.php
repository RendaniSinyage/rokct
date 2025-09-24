<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateContractTemplatesTable extends Migration
{
    public function up()
    {
        Schema::create('contract_templates', function (Blueprint $table) {
            $table->id();
            
            $table->string('title');
            $table->text('content');
            
            $table->string('loan_type')->default('personal');
            
            $table->decimal('min_amount', 10, 2);
            $table->decimal('max_amount', 10, 2);
            
            $table->boolean('is_default')->default(false);
            
            $table->decimal('base_interest_rate', 5, 2)->nullable();
            $table->integer('default_term_months')->nullable();
            
            $table->json('additional_terms')->nullable();
            
            $table->timestamps();
            
            // Unique constraint for default template
            $table->unique(['loan_type', 'is_default']);
        });
    }

    public function down()
    {
        Schema::dropIfExists('contract_templates');
    }
}
