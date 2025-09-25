CREATE TABLE `kpis` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `shop_id` bigint unsigned DEFAULT NULL,
  `objective_id` bigint unsigned NOT NULL,
  `metric` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `target_value` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `current_value` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `unit` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `due_date` date NOT NULL,
  `status` enum('Not Started','In Progress','Completed','Overdue') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Not Started',
  `completion_date` date DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `kpis_uuid_unique` (`uuid`),
  KEY `kpis_shop_id_foreign` (`shop_id`),
  KEY `kpis_objective_id_foreign` (`objective_id`),
  CONSTRAINT `kpis_objective_id_foreign` FOREIGN KEY (`objective_id`) REFERENCES `strategic_objectives` (`id`) ON DELETE CASCADE,
  CONSTRAINT `kpis_shop_id_foreign` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

