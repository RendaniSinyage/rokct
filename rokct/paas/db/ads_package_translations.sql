CREATE TABLE `ads_package_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `ads_package_id` bigint unsigned DEFAULT NULL,
  `locale` varchar(255) NOT NULL,
  `title` varchar(191) NOT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'new',
  `expired_at` datetime DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ads_package_translations_ads_package_id_locale_unique` (`ads_package_id`,`locale`),
  KEY `ads_package_translations_locale_index` (`locale`),
  CONSTRAINT `ads_package_translations_ads_package_id_foreign` FOREIGN KEY (`ads_package_id`) REFERENCES `ads_packages` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=57 DEFAULT CHARSET=utf8mb3;

INSERT INTO `ads_package_translations` VALUES (51,15,'en','Southriver Extra Free Bottle','new',NULL,NULL),(55,16,'en','KFC Special','new',NULL,NULL),(56,17,'en','Free Bottle','new',NULL,NULL);
