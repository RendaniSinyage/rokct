CREATE TABLE `parcel_order_settings` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `type` varchar(255) NOT NULL,
  `img` varchar(255) DEFAULT NULL,
  `min_width` smallint NOT NULL DEFAULT '0',
  `min_height` smallint NOT NULL DEFAULT '0',
  `min_length` smallint NOT NULL DEFAULT '0',
  `max_width` smallint NOT NULL DEFAULT '0',
  `max_height` smallint NOT NULL DEFAULT '0',
  `max_length` smallint NOT NULL DEFAULT '0',
  `min_g` int NOT NULL DEFAULT '100',
  `max_g` int NOT NULL DEFAULT '100',
  `price` double NOT NULL DEFAULT '0',
  `price_per_km` double NOT NULL DEFAULT '0',
  `special` tinyint(1) NOT NULL DEFAULT '0',
  `special_price` double DEFAULT '0',
  `special_price_per_km` double DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `max_range` smallint NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3;

INSERT INTO `parcel_order_settings` VALUES (1,'Gifts','https://s3.juvo.app/public/images/languages/101-1689336594.svg',11,12,12,111,12,12,13,14,30,11,0,0,0,'2023-07-14 10:05:43','2024-05-31 00:51:30',25),(2,'Documents','https://s3.juvo.app/public/images/languages/101-1689344276.svg',11,12,12,111,12,12,13,14,30,5,0,0,0,'2023-07-14 12:25:44','2024-05-31 00:52:19',25),(3,'Package','https://s3.juvo.app/public/images/languages/101-1689345262.svg',100,100,100,100,100,100,1000,5000,30,15,0,0,0,'2023-07-14 12:36:23','2024-05-31 00:52:31',25);
