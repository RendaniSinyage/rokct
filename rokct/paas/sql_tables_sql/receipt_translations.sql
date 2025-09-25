CREATE TABLE `receipt_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `receipt_id` bigint unsigned NOT NULL,
  `locale` varchar(255) NOT NULL,
  `title` varchar(191) NOT NULL,
  `description` text,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `receipt_translations_receipt_id_locale_unique` (`receipt_id`,`locale`),
  KEY `receipt_translations_locale_index` (`locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

