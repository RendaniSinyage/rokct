CREATE TABLE `coupon_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `coupon_id` bigint unsigned NOT NULL,
  `locale` varchar(255) NOT NULL,
  `title` varchar(191) NOT NULL,
  `description` text,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `coupon_translations_coupon_id_locale_unique` (`coupon_id`,`locale`),
  KEY `coupon_translations_locale_index` (`locale`),
  CONSTRAINT `coupon_translations_coupon_id_foreign` FOREIGN KEY (`coupon_id`) REFERENCES `coupons` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb3;

INSERT INTO `coupon_translations` VALUES (3,3,'en','R5Off',NULL,NULL),(4,4,'en','R10off',NULL,NULL),(5,5,'en','R20off',NULL,NULL),(6,2,'en','FREE100',NULL,NULL),(7,6,'en','FREE25',NULL,NULL);
