CREATE TABLE `backup_histories` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `status` tinyint(1) NOT NULL DEFAULT '1',
  `path` varchar(191) DEFAULT NULL,
  `created_by` bigint unsigned NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `backup_histories_created_by_foreign` (`created_by`),
  CONSTRAINT `backup_histories_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;

INSERT INTO `backup_histories` VALUES (1,'/backup_2023-06-03-23-36-09.zip',1,'/storage/laravel-backup//backup_2023-06-03-23-36-09.zip',101,NULL,'2023-06-03 21:36:22');
