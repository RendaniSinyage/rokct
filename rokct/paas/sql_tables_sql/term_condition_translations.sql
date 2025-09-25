CREATE TABLE `term_condition_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `term_condition_id` bigint unsigned NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `locale` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `term_condition_translations_term_condition_id_locale_unique` (`term_condition_id`,`locale`),
  KEY `term_condition_translations_locale_index` (`locale`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb3;

INSERT INTO `term_condition_translations` VALUES (10,10,'Terms of Use and Acceptable Use Policy','<p>These terms <strong>and</strong> conditions, together&nbsp;
