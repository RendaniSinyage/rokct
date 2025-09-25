CREATE TABLE `pillars` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `shop_id` bigint unsigned DEFAULT NULL,
  `vision_id` bigint unsigned NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `icon` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `color` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `display_order` int unsigned NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `pillars_uuid_unique` (`uuid`),
  KEY `pillars_shop_id_foreign` (`shop_id`),
  KEY `pillars_vision_id_foreign` (`vision_id`),
  CONSTRAINT `pillars_shop_id_foreign` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE,
  CONSTRAINT `pillars_vision_id_foreign` FOREIGN KEY (`vision_id`) REFERENCES `visions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `pillars` VALUES (1,'ed97e82a-e735-4ae4-b205-a4fb7387e3b2',NULL,2,'rere','erere','People',NULL,0,'2025-06-22 14:14:57','2025-06-22 14:14:57',NULL);
