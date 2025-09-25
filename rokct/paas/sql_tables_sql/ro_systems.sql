CREATE TABLE `ro_systems` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint unsigned NOT NULL,
  `membrane_count` int NOT NULL,
  `membrane_installation_date` timestamp NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ro_systems_shop_id_foreign` (`shop_id`),
  CONSTRAINT `ro_systems_shop_id_foreign` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `ro_systems` VALUES (31,9003,2,'2026-02-15 13:07:54','2025-01-20 15:56:42','2025-02-15 13:07:57');
