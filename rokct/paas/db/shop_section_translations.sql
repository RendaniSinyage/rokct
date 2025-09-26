CREATE TABLE `shop_section_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `locale` varchar(255) NOT NULL,
  `shop_section_id` bigint unsigned NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `description` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `shop_section_translations_shop_section_id_locale_unique` (`shop_section_id`,`locale`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;

INSERT INTO `shop_section_translations` VALUES (1,'test','en',1,NULL,NULL);
