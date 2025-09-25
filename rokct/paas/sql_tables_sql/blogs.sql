CREATE TABLE `blogs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` char(36) NOT NULL,
  `user_id` bigint unsigned NOT NULL,
  `type` tinyint NOT NULL DEFAULT '1',
  `published_at` date DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `img` varchar(191) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `blogs_user_id_foreign` (`user_id`),
  KEY `blogs_uuid_index` (`uuid`),
  KEY `blogs_type_index` (`type`),
  CONSTRAINT `blogs_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb3;

INSERT INTO `blogs` VALUES (1,'87f576d5-bb82-4314-86ba-5cba8e820b2c',101,2,'2023-03-23',1,NULL,'2023-03-23 10:48:40','2023-03-23 10:50:46',NULL),(2,'043c36ca-d06a-4365-b099-8ece2de16606',101,1,'2023-04-21',1,'https://s3.juvo.app/public/images/blogs/101-1682068328.webp','2023-04-21 06:43:56','2023-04-21 07:12:14',NULL),(3,'1b6ee5f2-8efd-4f11-b1dd-ca00d2cd7e7f',101,1,'2023-04-21',1,'https://s3.juvo.app/public/images/categories/101-1678415980.webp','2023-04-21 07:03:57','2023-04-21 07:09:20','2023-04-21 07:09:20'),(4,'2e3f02d2-e1fc-41d5-9a06-2504ea66de87',101,1,'2023-04-21',1,'https://s3.juvo.app/public/images/blogs/101-1682068452.webp','2023-04-21 07:08:30','2023-04-21 07:14:16',NULL),(5,'cb2014ab-60e9-4950-8ff9-8dd23ae20755',101,1,'2023-04-21',1,'https://s3.juvo.app/public/images/blogs/101-1684925972.webp','2023-04-21 07:09:10','2023-05-24 09:00:41',NULL),(6,'82e0fdf1-3139-4987-9e89-59e51419486d',101,1,'2023-05-24',1,'https://s3.juvo.app/public/images/blogs/101-1684925253.webp','2023-05-24 08:47:50','2023-05-24 08:50:10',NULL),(7,'dd52c627-707e-4b99-8d79-fab90252cd26',101,2,NULL,1,NULL,'2023-06-03 21:24:12','2023-06-03 21:24:22','2023-06-03 21:24:22'),(8,'5147b1a8-6342-4a56-ac77-965ddaae3654',101,2,'2024-01-11',1,NULL,'2024-01-11 13:40:49','2024-01-11 13:41:49',NULL),(9,'c30cfeec-4164-42bc-b6ad-f9432cb41e16',101,2,'2024-01-11',1,NULL,'2024-01-11 13:43:09','2024-01-11 13:43:50',NULL),(10,'a589901b-9c41-40e1-92c6-654edd40f7b0',101,2,'2024-04-07',1,NULL,'2024-04-07 20:57:28','2024-04-07 20:57:40',NULL),(11,'71e6497a-3e07-4dd6-9983-677b57b51456',101,2,'2024-04-07',1,NULL,'2024-04-07 21:01:50','2024-04-07 21:02:27',NULL);
