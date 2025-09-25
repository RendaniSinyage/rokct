CREATE TABLE `units` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `position` enum('before','after') NOT NULL DEFAULT 'after',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3;

INSERT INTO `units` VALUES (1,1,'after','2024-02-21 04:02:14','2024-02-21 04:02:14',NULL),(2,1,'after','2023-03-10 06:29:27','2023-03-10 06:29:27',NULL),(3,1,'after','2023-06-03 21:16:47','2023-06-03 21:16:47',NULL);
