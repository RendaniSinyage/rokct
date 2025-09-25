CREATE TABLE `product_properties` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `product_id` bigint unsigned NOT NULL,
  `locale` varchar(255) NOT NULL,
  `key` varchar(191) NOT NULL,
  `value` text,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `product_properties_product_id_foreign` (`product_id`),
  KEY `product_properties_locale_index` (`locale`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3;

INSERT INTO `product_properties` VALUES (3,67,'en','POS','yes','2024-04-30 11:58:49');
