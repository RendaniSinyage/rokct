CREATE TABLE `notifications` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `type` enum('push','discount','order_verify','order_statuses') NOT NULL,
  `payload` longtext,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `notifications_type_unique` (`type`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb3;

INSERT INTO `notifications` VALUES (1,'push',NULL,'2024-02-21 04:02:14','2024-02-21 04:02:14',NULL),(2,'discount',NULL,'2024-02-21 04:02:14','2024-02-21 04:02:14',NULL),(3,'order_verify',NULL,'2024-02-21 04:02:14','2024-02-21 04:02:14',NULL),(4,'order_statuses','[\"accepted\",\"ready\",\"delivered\",\"on_a_way\",\"canceled\"]','2024-02-21 04:02:14','2024-02-21 04:02:14',NULL);
