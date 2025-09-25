CREATE TABLE `strategic_objectives` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `shop_id` bigint unsigned DEFAULT NULL,
  `pillar_id` bigint unsigned NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `is_90_day_priority` tinyint(1) NOT NULL DEFAULT '0',
  `time_horizon` enum('Short-term','Medium-term','Long-term') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Short-term',
  `status` enum('Not Started','In Progress','Completed','Deferred') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Not Started',
  `start_date` date DEFAULT NULL,
  `target_date` date DEFAULT NULL,
  `completion_date` date DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `strategic_objectives_uuid_unique` (`uuid`),
  KEY `strategic_objectives_shop_id_foreign` (`shop_id`),
  KEY `strategic_objectives_pillar_id_foreign` (`pillar_id`),
  CONSTRAINT `strategic_objectives_pillar_id_foreign` FOREIGN KEY (`pillar_id`) REFERENCES `pillars` (`id`) ON DELETE CASCADE,
  CONSTRAINT `strategic_objectives_shop_id_foreign` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `strategic_objectives` VALUES (1,'494f32c3-df1a-4294-96bf-1a10bce15105',NULL,1,'sawwq','wqwqrwqrwq',0,'Short-term','Not Started',NULL,NULL,NULL,'2025-06-22 14:15:16','2025-06-22 14:15:16',NULL);
