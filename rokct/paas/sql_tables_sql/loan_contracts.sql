CREATE TABLE `loan_contracts` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `loan_application_id` bigint unsigned NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('pending_acceptance','accepted','declined','expired') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending_acceptance',
  `accepted_at` timestamp NULL DEFAULT NULL,
  `declined_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `interest_rate` decimal(5,2) DEFAULT NULL,
  `loan_term_months` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

