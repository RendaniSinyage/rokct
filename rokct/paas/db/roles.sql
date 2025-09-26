CREATE TABLE `roles` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `guard_name` varchar(255) NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `roles_name_guard_name_unique` (`name`,`guard_name`)
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb3;

INSERT INTO `roles` VALUES (1,'user','web',NULL,'2024-02-21 04:02:13','2024-02-21 04:02:13'),(11,'seller','web',NULL,'2024-02-21 04:02:13','2024-02-21 04:02:13'),(12,'moderator','web',NULL,'2024-02-21 04:02:13','2024-02-21 04:02:13'),(13,'deliveryman','web',NULL,'2024-02-21 04:02:13','2024-02-21 04:02:13'),(21,'manager','web',NULL,'2024-02-21 04:02:13','2024-02-21 04:02:13'),(31,'waiter','web',NULL,'2024-02-21 04:02:13','2024-02-21 04:02:13'),(41,'cook','web',NULL,'2024-02-21 04:02:13','2024-02-21 04:02:13'),(99,'admin','web',NULL,'2024-02-21 04:02:13','2024-02-21 04:02:13');
