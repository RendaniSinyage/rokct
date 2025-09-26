CREATE TABLE `receipt_nutrition_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `nutrition_id` bigint unsigned NOT NULL,
  `locale` varchar(255) NOT NULL,
  `title` varchar(191) NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `receipt_nutrition_translations_nutrition_id_locale_unique` (`nutrition_id`,`locale`),
  KEY `receipt_nutrition_translations_locale_index` (`locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

