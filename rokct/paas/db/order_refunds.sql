CREATE TABLE `order_refunds` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `status` enum('pending','accepted','canceled') NOT NULL DEFAULT 'pending',
  `cause` text,
  `answer` text,
  `order_id` bigint unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `order_refunds_order_id_foreign` (`order_id`),
  KEY `order_refunds_status_index` (`status`),
  CONSTRAINT `order_refunds_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;

INSERT INTO `order_refunds` VALUES (1,'canceled','Test','test',1262,'2023-06-04 13:32:17','2023-06-08 11:37:48');
