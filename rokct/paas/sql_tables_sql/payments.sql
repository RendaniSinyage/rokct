CREATE TABLE `payments` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `tag` varchar(255) DEFAULT NULL,
  `input` tinyint NOT NULL DEFAULT '2',
  `sandbox` tinyint(1) NOT NULL DEFAULT '0',
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb3;

INSERT INTO `payments` VALUES (1,'cash',1,0,1,'2022-12-16 17:04:13','2023-11-10 19:57:42',NULL),(2,'wallet',2,0,1,'2022-12-16 17:04:13','2023-06-04 06:31:03',NULL),(3,'paypal',9,0,0,'2022-12-16 17:04:13','2024-03-18 21:23:13',NULL),(4,'stripe',8,0,0,'2022-12-16 17:04:13','2024-03-18 21:23:08',NULL),(5,'paystack',5,0,0,'2022-12-16 17:04:13','2025-02-01 12:49:45',NULL),(6,'razorpay',7,0,0,'2022-12-16 17:04:13','2023-06-03 19:12:15',NULL),(8,'flutterWave',4,0,0,'2023-04-07 06:32:45','2024-08-08 09:30:50',NULL),(9,'mercado-pago',6,0,0,'2023-06-03 19:12:15','2023-06-03 19:12:52',NULL),(10,'paytabs',3,0,0,'2023-06-03 19:12:15','2023-06-03 19:12:48',NULL),(12,'pay-fast',2,1,1,NULL,'2024-10-21 07:49:21',NULL);
