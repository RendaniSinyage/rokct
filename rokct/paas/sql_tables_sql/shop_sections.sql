CREATE TABLE `shop_sections` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint unsigned NOT NULL,
  `area` varchar(255) DEFAULT NULL,
  `img` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `shop_sections_shop_id_foreign` (`shop_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;

INSERT INTO `shop_sections` VALUES (1,9003,'12.0',NULL,'2023-06-23 10:46:28','2023-06-23 10:46:28',NULL);
