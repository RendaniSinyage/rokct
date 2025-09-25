CREATE TABLE `banners` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `url` varchar(191) DEFAULT NULL,
  `type` varchar(255) NOT NULL DEFAULT 'banner',
  `img` varchar(191) DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `clickable` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `input` int NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `banners_type_index` (`type`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb3;

INSERT INTO `banners` VALUES (1,'https://gosouth.app','banner','https://s3.juvo.app/public/images/products/101-1699717011.webp',1,0,'2023-03-26 08:09:56','2024-04-06 20:12:33','2024-04-06 20:12:33',1),(2,'https://juvo.app','banner','https://s3.juvo.app/public/images/products/101-1699716121.webp',1,1,'2023-03-26 08:09:56','2024-04-29 12:45:47','2024-04-29 12:45:47',1),(3,'https://food.juvo.app','banner','https://s3.juvo.app/public/images/products/101-1712434278.webp',1,1,'2023-03-26 08:09:56','2024-04-29 13:28:43','2024-04-29 13:28:43',1),(4,'test','banner','https://s3.juvo.app/public/images/languages/101-1678368218.webp',1,1,'2023-03-30 18:30:52','2023-03-30 18:51:38','2023-03-30 18:51:38',1),(5,'shops','banner','https://s3.juvo.app/public/images/products/101-1712416037.webp',1,1,'2023-03-30 18:51:23','2024-04-29 12:45:42','2024-04-29 12:45:42',1),(6,'shops','banner','https://s3.juvo.app/public/images/products/101-1717511722.webp',1,0,'2024-04-06 17:51:15','2024-08-05 19:09:19','2024-08-05 19:09:19',1),(7,'parcel','banner','https://s3.juvo.app/public/images/products/101-1717510927.webp',1,0,'2024-04-06 19:01:07','2024-08-05 19:09:19','2024-08-05 19:09:19',1),(8,'https://food.juvo.app','banner','https://s3.juvo.app/public/images/shops/background/101-1678387995.webp',1,1,'2024-04-24 11:51:18','2024-08-05 19:09:19','2024-08-05 19:09:19',1),(9,'https://food.juvo.app','banner','https://s3.juvo.app/public/images/products/101-1712434278.webp',1,1,'2024-04-29 13:05:45','2024-04-29 13:05:51','2024-04-29 13:05:51',1),(10,'https://food.juvo.app','banner','https://s3.juvo.app/public/images/products/101-1714397217.webp',1,1,'2024-04-29 13:06:15','2024-08-05 19:09:19','2024-08-05 19:09:19',1),(11,'shop','banner','https://s3.juvo.app/public/images/products/101-1717511258.webp',1,1,'2024-05-21 21:47:12','2024-08-05 19:09:19','2024-08-05 19:09:19',1),(12,'shop','banner','https://s3.juvo.app/public/images/products/101-1721246241.webp',1,1,'2024-07-17 15:15:59','2024-08-05 19:09:19','2024-08-05 19:09:19',1),(13,'shop','banner','https://s3.juvo.app/public/images/shops/background/101-1721855317.webp',1,1,'2024-08-05 19:19:47','2024-08-05 19:28:21','2024-08-05 19:28:21',1),(14,'shop','banner','https://s3.juvo.app/public/images/products/101-1722893357.webp',1,1,'2024-08-05 19:29:24','2024-08-05 19:30:45','2024-08-05 19:30:45',1),(15,'shop','banner','https://s3.juvo.app/public/images/products/101-1722893357.webp',1,1,'2024-08-05 19:30:38','2024-08-05 19:30:38',NULL,1);
