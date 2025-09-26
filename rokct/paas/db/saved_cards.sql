CREATE TABLE `saved_cards` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint unsigned NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_four` varchar(4) COLLATE utf8mb4_unicode_ci NOT NULL,
  `card_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiry_date` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `card_holder_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `saved_cards_user_id_foreign` (`user_id`),
  CONSTRAINT `saved_cards_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

