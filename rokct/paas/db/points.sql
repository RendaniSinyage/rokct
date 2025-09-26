CREATE TABLE `points` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint unsigned DEFAULT NULL,
  `type` varchar(255) NOT NULL DEFAULT 'fix',
  `price` double NOT NULL DEFAULT '0',
  `value` int NOT NULL DEFAULT '0',
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `points_shop_id_foreign` (`shop_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3;

INSERT INTO `points` VALUES (1,502,'percent',10,150,1,'2023-03-25 12:29:06','2023-03-26 16:19:08','2023-03-26 16:19:08'),(3,9003,'percent',1,25,1,'2023-06-04 10:06:33','2024-04-27 22:21:36',NULL);
