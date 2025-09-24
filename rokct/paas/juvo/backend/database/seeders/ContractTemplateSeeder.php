public function run()
{
    ContractTemplate::create([
        'title' => 'Personal Loan Agreement',
        'content' => 'This Loan Agreement is made between {USER_NAME} and our institution.

Loan Details:
- Loan Amount: R{LOAN_AMOUNT}
- ID Number: {ID_NUMBER}
- Interest Rate: {INTEREST_RATE}%
- Repayment Period: {REPAYMENT_PERIOD} months

Terms and Conditions:
1. The borrower agrees to repay the full loan amount.
2. Interest will be calculated monthly.
3. Late payments will incur additional fees.
4. Failure to repay may result in legal action.

By accepting this contract, you agree to the above terms.',
        'loan_type' => 'personal',
        'min_amount' => 200,
        'max_amount' => 10000,
        'is_default' => true
    ]);
}
