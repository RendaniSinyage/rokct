CREATE TABLE `shop_closed_dates` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint unsigned NOT NULL,
  `date` date NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `shop_closed_dates_shop_id_foreign` (`shop_id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb3;

INSERT INTO `shop_closed_dates` VALUES (1,503,'2023-03-20','2023-03-18 09:32:31','2023-03-18 10:07:39','2023-03-18 10:07:39'),(2,503,'2023-03-20','2023-03-18 10:07:39','2023-03-18 14:48:35','2023-03-18 14:48:35'),(7,505,'2023-03-20','2023-03-18 14:39:18','2023-03-23 11:47:15','2023-03-23 11:47:15'),(8,9000,'2023-03-20','2023-03-18 14:46:14','2023-03-26 12:15:34','2023-03-26 12:15:34'),(9,503,'2023-03-20','2023-03-18 14:48:35','2023-03-21 16:41:52','2023-03-21 16:41:52'),(10,510,'2023-03-20','2023-03-18 14:46:14','2023-04-25 08:29:20','2023-04-25 08:29:20');
