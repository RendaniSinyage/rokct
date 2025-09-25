CREATE TABLE `currencies` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `symbol` varchar(255) DEFAULT NULL,
  `title` varchar(191) NOT NULL,
  `position` enum('before','after') NOT NULL DEFAULT 'after',
  `default` tinyint(1) NOT NULL DEFAULT '0',
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `rate` double NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3;

INSERT INTO `currencies` VALUES (3,'R','ZAR','before',1,1,'2023-03-09 10:45:07','2025-06-19 03:14:24',NULL,1);
