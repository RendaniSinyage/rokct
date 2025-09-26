CREATE TABLE `shop_subscriptions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint unsigned NOT NULL,
  `subscription_id` bigint unsigned NOT NULL,
  `expired_at` date DEFAULT NULL,
  `price` double DEFAULT NULL,
  `type` varchar(255) DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `shop_subscriptions_shop_id_foreign` (`shop_id`),
  KEY `shop_subscriptions_subscription_id_foreign` (`subscription_id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb3;

INSERT INTO `shop_subscriptions` VALUES (3,502,104,'2023-09-23',500,'shop',1,'2023-03-23 16:11:12','2023-03-23 16:11:13',NULL),(4,502,105,'2024-03-23',800,'shop',1,'2023-03-23 16:11:34','2023-03-23 16:11:34',NULL);
