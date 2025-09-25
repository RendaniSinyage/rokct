CREATE TABLE `shop_tags` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `img` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb3;

INSERT INTO `shop_tags` VALUES (1,'https://s3.juvo.app/public/images/shop-tags/101-1678369266.webp','2023-03-18 07:57:44','2023-12-01 09:27:00','2023-12-01 09:27:00'),(2,'https://s3.juvo.app/public/images/shop-tags/101-1679148057.gif','2023-03-18 07:58:58','2023-12-01 09:27:00','2023-12-01 09:27:00'),(3,'https://s3.juvo.app/public/images/products/101-1679147982.gif','2023-03-18 08:00:24','2023-12-01 09:26:39',NULL),(4,'https://s3.juvo.app/public/images/shop-tags/101-1679148057.gif','2023-04-25 06:09:28','2024-02-21 09:44:25',NULL),(5,'https://s3.juvo.app/public/images/shop-tags/101-1678369266.webp','2023-04-25 06:09:42','2024-02-21 09:42:53',NULL),(6,'https://s3.juvo.app/public/images/products/101-1691677458.webp','2023-08-10 12:24:21','2023-12-01 09:27:00','2023-12-01 09:27:00');
