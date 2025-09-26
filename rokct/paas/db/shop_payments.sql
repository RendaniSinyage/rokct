CREATE TABLE `shop_payments` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `payment_id` bigint unsigned NOT NULL,
  `shop_id` bigint unsigned NOT NULL,
  `status` tinyint(1) NOT NULL DEFAULT '0',
  `client_id` varchar(191) DEFAULT NULL,
  `secret_id` varchar(191) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `shop_payments_payment_id_foreign` (`payment_id`),
  KEY `shop_payments_shop_id_foreign` (`shop_id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb3;

INSERT INTO `shop_payments` VALUES (1,1,502,1,NULL,NULL,'2023-03-23 13:10:25','2023-03-23 13:10:25',NULL),(2,2,502,1,NULL,NULL,'2023-03-23 13:10:32','2023-03-23 13:10:32',NULL),(3,1,9003,1,NULL,NULL,'2023-06-05 16:29:30','2024-07-04 14:28:32','2024-07-04 14:28:32'),(4,2,9003,1,NULL,NULL,'2023-06-05 16:29:37','2024-08-07 23:08:59','2024-08-07 23:08:59'),(5,5,9003,1,'9001','test','2023-06-12 10:48:30','2023-06-12 10:49:18','2023-06-12 10:49:18'),(6,1,504,0,NULL,NULL,'2023-06-28 16:00:21','2023-06-28 16:00:21',NULL),(7,1,9003,0,NULL,NULL,'2024-07-04 14:30:26','2024-08-07 23:09:03','2024-08-07 23:09:03'),(8,12,9003,1,'9001','test','2024-08-07 23:09:21','2024-08-08 09:16:16','2024-08-08 09:16:16'),(9,2,9003,1,NULL,NULL,'2024-08-07 23:12:24','2024-08-07 23:12:24',NULL),(10,1,9003,1,NULL,NULL,'2024-08-08 09:16:34','2024-08-08 09:16:34',NULL);
