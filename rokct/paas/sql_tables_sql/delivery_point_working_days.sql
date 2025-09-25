CREATE TABLE `delivery_point_working_days` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `delivery_point_id` bigint unsigned NOT NULL,
  `day` enum('monday','tuesday','wednesday','thursday','friday','saturday','sunday') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `from` varchar(5) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '9:00',
  `to` varchar(5) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '21:00',
  `disabled` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `delivery_point_working_days_delivery_point_id_foreign` (`delivery_point_id`),
  CONSTRAINT `delivery_point_working_days_delivery_point_id_foreign` FOREIGN KEY (`delivery_point_id`) REFERENCES `delivery_points` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

