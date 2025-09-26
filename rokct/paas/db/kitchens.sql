CREATE TABLE `kitchens` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint unsigned NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `kitchens_shop_id_foreign` (`shop_id`),
  CONSTRAINT `kitchens_shop_id_foreign` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3;

INSERT INTO `kitchens` VALUES (1,505,1,'2024-07-13 13:40:04','2024-07-13 13:40:04'),(2,9003,1,'2024-10-17 07:30:04','2024-10-17 07:30:04');
