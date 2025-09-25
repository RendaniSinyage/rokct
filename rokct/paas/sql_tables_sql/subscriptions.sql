CREATE TABLE `subscriptions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `type` varchar(255) NOT NULL DEFAULT 'orders',
  `price` double NOT NULL,
  `month` tinyint NOT NULL,
  `active` tinyint(1) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `product_limit` int NOT NULL,
  `order_limit` int NOT NULL,
  `with_report` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=101 DEFAULT CHARSET=utf8mb3;

INSERT INTO `subscriptions` VALUES (97,'orders',100,1,1,'2024-02-21 04:02:13','2024-02-21 04:02:13',NULL,'title1',1000,1000,0),(98,'orders',250,3,1,'2024-02-21 04:02:13','2024-02-21 04:02:13',NULL,'title3',3000,3000,1),(99,'orders',450,6,1,'2024-02-21 04:02:13','2024-02-21 04:02:13',NULL,'title6',6000,6000,1),(100,'orders',800,12,1,'2024-02-21 04:02:13','2024-02-21 04:02:13',NULL,'title12',12000,12000,1);
