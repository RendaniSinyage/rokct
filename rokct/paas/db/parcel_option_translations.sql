CREATE TABLE `parcel_option_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `parcel_option_id` bigint unsigned NOT NULL,
  `locale` varchar(255) NOT NULL,
  `title` varchar(191) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `parcel_option_translations_parcel_option_id_locale_unique` (`parcel_option_id`,`locale`),
  KEY `parcel_option_translations_locale_index` (`locale`),
  CONSTRAINT `parcel_option_translations_parcel_option_id_foreign` FOREIGN KEY (`parcel_option_id`) REFERENCES `parcel_options` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

