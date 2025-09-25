CREATE TABLE `personal_mastery_goals` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint unsigned NOT NULL,
  `area` enum('Financial','Vocation/Work','Family','Friends','Spiritual','Physical','Learning & Skills') COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `related_objective_id` bigint unsigned DEFAULT NULL,
  `target_date` date DEFAULT NULL,
  `status` enum('Not Started','In Progress','Completed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Not Started',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `personal_mastery_goals_uuid_unique` (`uuid`),
  KEY `personal_mastery_goals_user_id_foreign` (`user_id`),
  KEY `personal_mastery_goals_related_objective_id_foreign` (`related_objective_id`),
  CONSTRAINT `personal_mastery_goals_related_objective_id_foreign` FOREIGN KEY (`related_objective_id`) REFERENCES `strategic_objectives` (`id`) ON DELETE SET NULL,
  CONSTRAINT `personal_mastery_goals_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

