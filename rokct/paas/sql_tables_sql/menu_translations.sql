CREATE TABLE `menu_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `menu_id` bigint unsigned NOT NULL,
  `locale` varchar(255) NOT NULL,
  `title` varchar(191) NOT NULL,
  `description` text,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `menu_translations_menu_id_locale_unique` (`menu_id`,`locale`),
  KEY `menu_translations_locale_index` (`locale`),
  CONSTRAINT `menu_translations_menu_id_foreign` FOREIGN KEY (`menu_id`) REFERENCES `menus` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

