CREATE TABLE `tag_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `tag_id` bigint unsigned NOT NULL,
  `locale` varchar(255) NOT NULL,
  `title` varchar(191) NOT NULL,
  `description` mediumtext,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tag_translations_tag_id_locale_unique` (`tag_id`,`locale`),
  KEY `tag_translations_locale_index` (`locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

