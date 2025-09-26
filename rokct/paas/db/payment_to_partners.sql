CREATE TABLE `payment_to_partners` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `order_id` bigint unsigned NOT NULL,
  `type` varchar(255) NOT NULL DEFAULT 'seller',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `payment_to_partners_user_id_foreign` (`user_id`),
  KEY `payment_to_partners_order_id_foreign` (`order_id`),
  CONSTRAINT `payment_to_partners_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `payment_to_partners_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3;

INSERT INTO `payment_to_partners` VALUES (1,147,2789,'seller',NULL,'2024-08-01 22:07:53','2024-08-01 22:07:53'),(2,147,2793,'seller',NULL,'2024-08-01 22:08:40','2024-08-01 22:08:40'),(3,147,2778,'seller',NULL,'2024-08-01 22:09:33','2024-08-01 22:09:33');
