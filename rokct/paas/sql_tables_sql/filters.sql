CREATE TABLE `filters` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `ro_system_id` bigint unsigned NOT NULL,
  `external_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` enum('birm','sediment','carbonBlock') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `location` enum('pre','ro','post') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `installation_date` timestamp NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `filters_external_id_unique` (`external_id`),
  KEY `filters_ro_system_id_foreign` (`ro_system_id`),
  CONSTRAINT `filters_ro_system_id_foreign` FOREIGN KEY (`ro_system_id`) REFERENCES `ro_systems` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=129 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `filters` VALUES (125,31,'pre_1737388585642','sediment','pre','2025-09-10 20:01:17','2025-08-12 03:01:17','2025-08-12 03:01:17'),(126,31,'ro_1737388587362','sediment','ro','2025-09-10 20:01:17','2025-08-12 03:01:17','2025-08-12 03:01:17'),(127,31,'post_1737391682566','sediment','post','2025-09-10 20:01:17','2025-08-12 03:01:17','2025-08-12 03:01:17'),(128,31,'post_1737391683746','carbonBlock','post','2025-09-10 20:01:17','2025-08-12 03:01:17','2025-08-12 03:01:17');
