CREATE TABLE `success_wheel_elements` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `shop_id` bigint unsigned DEFAULT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `category` enum('Leadership & Vision','Human Resource','Technology & Communications','Operational & Quality Management Systems','Financial Sustainability','Legislation & Compliance','Sales & Marketing','Product or Service','Social & Environmental Impact') COLLATE utf8mb4_unicode_ci NOT NULL,
  `related_pillar_id` bigint unsigned NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `score` int NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `success_wheel_elements_uuid_unique` (`uuid`),
  KEY `success_wheel_elements_shop_id_foreign` (`shop_id`),
  KEY `success_wheel_elements_related_pillar_id_foreign` (`related_pillar_id`),
  CONSTRAINT `success_wheel_elements_related_pillar_id_foreign` FOREIGN KEY (`related_pillar_id`) REFERENCES `pillars` (`id`) ON DELETE CASCADE,
  CONSTRAINT `success_wheel_elements_shop_id_foreign` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

