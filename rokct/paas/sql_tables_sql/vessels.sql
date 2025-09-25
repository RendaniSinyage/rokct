CREATE TABLE `vessels` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `ro_system_id` bigint unsigned NOT NULL,
  `external_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` enum('megaChar','softener') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `installation_date` timestamp NOT NULL,
  `last_maintenance_date` timestamp NULL DEFAULT NULL,
  `current_stage` enum('initialCheck','pressureRelease','backwash','settling','fastWash','brineAndSlowRinse','fastRinse','brineRefill','stabilization','returnToService','returnToFilter') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `maintenance_start_time` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `vessels_external_id_unique` (`external_id`),
  KEY `vessels_ro_system_id_foreign` (`ro_system_id`),
  CONSTRAINT `vessels_ro_system_id_foreign` FOREIGN KEY (`ro_system_id`) REFERENCES `ro_systems` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=104 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `vessels` VALUES (102,31,'megaChar_0','megaChar','2025-09-10 20:01:17',NULL,NULL,NULL,'2025-08-12 03:01:17','2025-08-12 03:01:17'),(103,31,'softener_0','softener','2025-09-10 20:01:17',NULL,NULL,NULL,'2025-08-12 03:01:17','2025-08-12 03:01:17');
