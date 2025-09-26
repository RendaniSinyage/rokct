CREATE TABLE `delivery_point_closed_dates` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `delivery_point_id` bigint unsigned NOT NULL,
  `date` date NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `delivery_point_closed_dates_delivery_point_id_foreign` (`delivery_point_id`),
  CONSTRAINT `delivery_point_closed_dates_delivery_point_id_foreign` FOREIGN KEY (`delivery_point_id`) REFERENCES `delivery_points` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

