CREATE TABLE `reviews` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `reviewable_type` varchar(255) NOT NULL,
  `reviewable_id` bigint unsigned NOT NULL,
  `assignable_type` varchar(255) DEFAULT NULL,
  `assignable_id` bigint unsigned DEFAULT NULL,
  `user_id` bigint unsigned DEFAULT NULL,
  `rating` double NOT NULL DEFAULT '5',
  `comment` text,
  `img` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `reviews_reviewable_type_reviewable_id_index` (`reviewable_type`,`reviewable_id`),
  KEY `reviews_assignable_type_assignable_id_index` (`assignable_type`,`assignable_id`),
  KEY `reviews_reviewable_id_index` (`reviewable_id`),
  KEY `reviews_reviewable_type_index` (`reviewable_type`),
  KEY `reviews_user_id_foreign` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb3;

INSERT INTO `reviews` VALUES (1,'App\\Models\\Order',1008,'App\\Models\\Shop',507,119,4,NULL,NULL,'2023-03-23 12:42:45','2023-03-23 12:42:45',NULL),(2,'App\\Models\\Order',1007,'App\\Models\\Shop',502,119,5,NULL,NULL,'2023-03-23 12:43:13','2023-03-23 12:43:13',NULL),(4,'App\\Models\\Order',2651,'App\\Models\\User',101,137,4,NULL,NULL,'2024-04-01 09:35:17','2024-04-01 09:35:17',NULL),(5,'App\\Models\\Order',2718,'App\\Models\\User',306,137,4,NULL,NULL,'2024-04-22 11:26:55','2024-04-22 11:26:55',NULL),(6,'App\\Models\\Order',2696,'App\\Models\\Shop',504,101,5,NULL,NULL,'2024-04-28 20:26:05','2024-04-28 20:26:05',NULL),(7,'App\\Models\\Order',2695,'App\\Models\\Shop',504,101,5,NULL,NULL,'2024-04-28 20:26:23','2024-04-28 20:26:23',NULL),(8,'App\\Models\\Order',2659,'App\\Models\\Shop',505,101,4,NULL,NULL,'2024-04-28 20:26:33','2024-04-28 20:26:33',NULL),(9,'App\\Models\\Order',2658,'App\\Models\\Shop',504,101,4,NULL,NULL,'2024-04-28 20:26:45','2024-04-28 20:26:45',NULL),(10,'App\\Models\\Order',2718,'App\\Models\\Shop',9003,306,5,NULL,NULL,'2024-04-28 20:28:46','2024-04-28 20:28:46',NULL),(11,'App\\Models\\Order',2714,'App\\Models\\Shop',9003,306,5,NULL,NULL,'2024-04-28 20:28:53','2024-04-28 20:28:53',NULL),(12,'App\\Models\\Order',2712,'App\\Models\\Shop',9003,306,5,NULL,NULL,'2024-04-28 20:29:00','2024-04-28 20:29:00',NULL),(13,'App\\Models\\Order',2756,'App\\Models\\Shop',9003,702,5,NULL,NULL,'2024-08-01 22:20:30','2024-08-01 22:20:30',NULL),(14,'App\\Models\\Order',2654,'App\\Models\\Shop',9003,109,5,NULL,NULL,'2024-08-01 22:25:26','2024-08-01 22:25:26',NULL),(15,'App\\Models\\Order',2689,'App\\Models\\Shop',9003,575,5,NULL,NULL,'2024-10-21 09:29:11','2024-10-21 09:29:11',NULL);
