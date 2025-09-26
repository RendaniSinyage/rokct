CREATE TABLE `discounts` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint unsigned NOT NULL,
  `type` enum('fix','percent') NOT NULL,
  `price` double NOT NULL,
  `start` date NOT NULL DEFAULT '2023-06-20',
  `end` date DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `img` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `discounts_shop_id_foreign` (`shop_id`),
  CONSTRAINT `discounts_shop_id_foreign` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;

INSERT INTO `discounts` VALUES (1,9003,'percent',10,'2024-07-07','2024-07-09',1,'https://s3.juvo.app/public/images/products/101-1688387651.webp','2024-07-07 21:13:35','2024-07-15 16:57:26','2024-07-15 16:57:26');
