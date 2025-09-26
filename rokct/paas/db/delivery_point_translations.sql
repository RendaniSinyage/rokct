CREATE TABLE `delivery_point_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `delivery_point_id` bigint unsigned NOT NULL,
  `locale` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`),
  UNIQUE KEY `delivery_point_translations_delivery_point_id_locale_unique` (`delivery_point_id`,`locale`),
  KEY `delivery_point_translations_locale_index` (`locale`),
  CONSTRAINT `delivery_point_translations_delivery_point_id_foreign` FOREIGN KEY (`delivery_point_id`) REFERENCES `delivery_points` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

