CREATE TABLE `combo_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `combo_id` bigint unsigned NOT NULL,
  `locale` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`),
  KEY `combo_translations_combo_id_foreign` (`combo_id`),
  KEY `combo_translations_locale_index` (`locale`),
  KEY `combo_translations_title_index` (`title`),
  CONSTRAINT `combo_translations_combo_id_foreign` FOREIGN KEY (`combo_id`) REFERENCES `combos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

