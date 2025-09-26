CREATE TABLE `unit_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `unit_id` bigint unsigned NOT NULL,
  `locale` varchar(255) NOT NULL,
  `title` varchar(191) NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unit_translations_unit_id_locale_unique` (`unit_id`,`locale`),
  KEY `unit_translations_locale_index` (`locale`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb3;

INSERT INTO `unit_translations` VALUES (2,2,'en','Pack',NULL),(3,3,'en','kg',NULL),(4,1,'en','pcs',NULL);
