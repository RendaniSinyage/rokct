CREATE TABLE `apps` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `shop_id` bigint unsigned DEFAULT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `package_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `platform` enum('iOS','Android','Web','Cross-Platform') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Cross-Platform',
  `icon` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `current_version` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `apps_uuid_unique` (`uuid`),
  KEY `apps_shop_id_foreign` (`shop_id`),
  CONSTRAINT `apps_shop_id_foreign` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `apps` VALUES (1,'014115ba-abaa-4a9c-96fb-4f149d69eadb',NULL,'Customer App','food.juvo.app',NULL,'Android',NULL,NULL,'2025-05-19 16:14:52','2025-05-19 16:14:52',NULL);
