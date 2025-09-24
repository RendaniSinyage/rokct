<?php

namespace Database\Seeders;

use App\Models\ContractTemplate;
use Illuminate\Database\Seeder;

class DefaultContractTemplateSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        // Insert default contract template if no default exists
        $defaultExists = ContractTemplate::where('is_default', true)
            ->where('loan_type', 'personal')
            ->exists();

        if (!$defaultExists) {
            ContractTemplate::create([
                'title' => 'Default Personal Loan Contract',
                'loan_type' => 'personal',
                'content' => 'LOAN AGREEMENT

This Loan Agreement ("Agreement") is entered into on {DATE} between the Lender and the Borrower.

BORROWER: {USER_NAME} (ID Number: {ID_NUMBER})
LENDER: Juvo Financial Services

1. LOAN AMOUNT: R{LOAN_AMOUNT}

2. INTEREST RATE: {INTEREST_RATE}% per annum

3. TERM: {REPAYMENT_PERIOD} months from the date of this Agreement.

4. REPAYMENT: The Borrower agrees to repay the Loan Amount plus accrued interest in equal monthly installments over the Term.

5. DEFAULT: Failure to make any payment within 5 days of the due date will constitute default.

6. GOVERNING LAW: This Agreement is governed by the laws of South Africa.

The Borrower acknowledges having read, understood, and agreed to the terms of this Agreement.

Borrower: {USER_NAME}
Date: {DATE}',
                'min_amount' => 200.00,
                'max_amount' => 10000.00,
                'base_interest_rate' => 15.50,
                'default_term_months' => 36,
                'is_default' => true,
                'additional_terms' => json_encode([
                    'late_fee_percentage' => 5,
                    'grace_period_days' => 5,
                ]),
            ]);
        }
    }
}
