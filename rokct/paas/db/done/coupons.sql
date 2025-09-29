CREATE TABLE `coupons` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `type` enum('fix','percent') NOT NULL DEFAULT 'fix',
  `qty` int NOT NULL DEFAULT '0',
  `price` double NOT NULL DEFAULT '0',
  `expired_at` datetime NOT NULL,
  `img` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `for` varchar(255) NOT NULL DEFAULT 'total_price',
  PRIMARY KEY (`id`),
  UNIQUE KEY `coupons_shop_id_name_unique` (`shop_id`,`name`),
  KEY `coupons_name_index` (`name`),
  CONSTRAINT `coupons_shop_id_foreign` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb3;

INSERT INTO `coupons` VALUES (2,9003,'FREE100','fix',1,100,'2026-10-10 00:00:00',NULL,'2023-06-15 16:18:23','2024-10-30 12:41:52',NULL,'total_price'),(3,9003,'R5Off','fix',999999998,5,'2027-12-11 00:00:00',NULL,'2024-10-30 12:38:01','2024-10-30 12:52:42',NULL,'total_price'),(4,9003,'R10off','fix',2147483645,10,'2027-11-03 00:00:00',NULL,'2024-10-30 12:40:44','2024-10-30 13:39:15',NULL,'total_price'),(5,9003,'R20off','fix',2147483647,20,'2027-11-06 00:00:00',NULL,'2024-10-30 12:41:30','2024-10-30 12:41:30',NULL,'total_price'),(6,9003,'FREE25','fix',2147483633,25,'2027-12-11 00:00:00',NULL,'2024-11-30 09:43:36','2025-08-25 16:19:47',NULL,'total_price');
