CREATE TABLE `banner_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `banner_id` bigint unsigned NOT NULL,
  `locale` varchar(255) NOT NULL,
  `title` varchar(191) NOT NULL,
  `description` text,
  `button_text` varchar(255) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `banner_translations_banner_id_locale_unique` (`banner_id`,`locale`),
  KEY `banner_translations_locale_index` (`locale`),
  CONSTRAINT `banner_translations_banner_id_foreign` FOREIGN KEY (`banner_id`) REFERENCES `banners` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=91 DEFAULT CHARSET=utf8mb3;

INSERT INTO `banner_translations` VALUES (18,4,'en','Title','Banner','Banner',NULL),(31,1,'en','Every Day Low Prices.','Shop South River today for Every Day Low Prices.','show',NULL),(54,5,'en','Every Day Low Prices.','Shop South River today for Every Day Low Prices.','show',NULL),(55,2,'en','We Deliver','We deliver even when there is loadshedding','show',NULL),(59,8,'en','kfc special','kfc special','show',NULL),(60,3,'en','Every Day Low Prices.','Shop South River today for Every Day Low Prices.','show',NULL),(61,9,'en','Free Bottle','Shop South River today for Every Day Low Prices.','show',NULL),(81,11,'en','nandos','peri peri','order',NULL),(82,6,'en','loadshedding','loadsheding','show',NULL),(84,7,'en','kfc','kfcfree','Send',NULL),(85,10,'en','Free 5L Bottle','Shop South River today for Every Day Low Prices.','show',NULL),(87,12,'en','test','parcel','show',NULL),(88,13,'en','kfc special','special','show',NULL),(89,14,'en','Free 5L Bottle','special','show',NULL),(90,15,'en','Free 5L Bottle2','special','show',NULL);
