CREATE TABLE `contract_templates` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `loan_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'personal',
  `min_amount` decimal(10,2) NOT NULL,
  `max_amount` decimal(10,2) NOT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `base_interest_rate` decimal(5,2) DEFAULT NULL,
  `default_term_months` int DEFAULT NULL,
  `additional_terms` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `contract_templates_loan_type_is_default_unique` (`loan_type`,`is_default`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `contract_templates` VALUES (1,'Default Personal Loan Contract','LOAN AGREEMENT\n\nThis Loan Agreement (\"Agreement\") is entered into on {DATE} between the Lender and the Borrower.\n\nBORROWER: {USER_NAME} (ID Number: {ID_NUMBER})\nLENDER: Juvo Financial Services\n\n1. LOAN AMOUNT: R{LOAN_AMOUNT}\n\n2. INTEREST RATE: {INTEREST_RATE}% per annum\n\n3. TERM: {REPAYMENT_PERIOD} months from the date of this Agreement.\n\n4. REPAYMENT: The Borrower agrees to repay the Loan Amount plus accrued interest in equal monthly installments over the Term.\n\n5. DEFAULT: Failure to make any payment within 5 days of the due date will constitute default.\n\n6. GOVERNING LAW: This Agreement is governed by the laws of South Africa.\n\nThe Borrower acknowledges having read, understood, and agreed to the terms of this Agreement.\n\nBorrower: {USER_NAME}\nDate: {DATE}','personal',200.00,10000.00,1,15.50,36,'\"{\\\"late_fee_percentage\\\":5,\\\"grace_period_days\\\":5}\"','2025-05-19 12:10:03','2025-05-19 12:10:03');
