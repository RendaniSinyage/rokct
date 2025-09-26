CREATE TABLE `shop_ads_packages` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `active` tinyint(1) NOT NULL DEFAULT '0',
  `ads_package_id` bigint unsigned NOT NULL,
  `shop_id` bigint unsigned NOT NULL,
  `banner_id` bigint unsigned DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'new',
  `position_page` int DEFAULT '2147483647',
  `expired_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `shop_ads_packages_ads_package_id_foreign` (`ads_package_id`),
  KEY `shop_ads_packages_shop_id_foreign` (`shop_id`),
  KEY `shop_ads_packages_banner_id_foreign` (`banner_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb3;

INSERT INTO `shop_ads_packages` VALUES (1,1,15,9003,10,'2024-04-29 13:10:42','approved',2147483647,'2046-04-29 13:10:10'),(2,0,15,504,2,'2024-04-23 09:05:00','new',2147483647,NULL),(4,1,16,504,13,NULL,'approved',2147483647,'2046-08-05 21:26:57'),(5,0,16,9000,2,'2024-04-29 11:51:24','new',2147483647,NULL),(6,1,17,9003,15,NULL,'approved',2147483647,'2046-08-05 21:32:19');
