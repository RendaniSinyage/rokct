CREATE TABLE `memberships` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `price` decimal(10,2) NOT NULL DEFAULT '0.00',
  `duration` int NOT NULL DEFAULT '30',
  `duration_unit` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'days',
  `description` text COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `memberships` VALUES (1,'Basic Plan','monthly',9.99,30,'days','Basic membership with standard features',1,'2025-05-19 12:12:33','2025-05-19 12:12:33'),(2,'Premium Plan','monthly',19.99,30,'days','Premium membership with advanced features',1,'2025-05-19 12:12:33','2025-05-19 12:12:33'),(3,'Gold Plan','yearly',99.99,365,'days','Gold membership with all features and benefits',1,'2025-05-19 12:12:33','2025-05-19 12:12:33');
