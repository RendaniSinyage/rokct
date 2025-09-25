CREATE TABLE `loan_applications` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `id_number` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL,
  `status` enum('incomplete','pending_review','pending_contract','pending_disbursal','active','rejected','paid_off','overdue','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'incomplete',
  `documents` json DEFAULT NULL,
  `additional_data` json DEFAULT NULL,
  `contract_accepted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `loan_applications_user_id_foreign` (`user_id`),
  CONSTRAINT `loan_applications_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

