CREATE TABLE `shop_tag_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `shop_tag_id` bigint unsigned NOT NULL,
  `title` varchar(255) NOT NULL,
  `locale` varchar(255) NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `shop_tag_translations_shop_tag_id_locale_unique` (`shop_tag_id`,`locale`),
  KEY `shop_tag_translations_locale_index` (`locale`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb3;

INSERT INTO `shop_tag_translations` VALUES (3,3,'Water','en',NULL),(10,4,'Vegan','en',NULL),(11,5,'Halal','en',NULL);
