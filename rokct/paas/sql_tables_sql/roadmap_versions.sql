CREATE TABLE `roadmap_versions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `app_id` bigint unsigned NOT NULL,
  `version_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('Planning','Development','Testing','Released') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Planning',
  `description` text COLLATE utf8mb4_unicode_ci,
  `features` json DEFAULT NULL,
  `release_date` date DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `roadmap_versions_app_id_version_number_unique` (`app_id`,`version_number`),
  UNIQUE KEY `roadmap_versions_uuid_unique` (`uuid`),
  CONSTRAINT `roadmap_versions_app_id_foreign` FOREIGN KEY (`app_id`) REFERENCES `apps` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `roadmap_versions` VALUES (1,'f03717fe-9b7c-41a6-9033-94ec1bc6d221',1,'2.5.7','Planning',NULL,'[\"test\"]',NULL,'2025-05-19 16:15:34','2025-05-19 16:15:34',NULL);
