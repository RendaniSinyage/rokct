CREATE TABLE `meter_readings` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `meterId` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `reading` int NOT NULL,
  `timestamp` timestamp NOT NULL,
  `userId` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `shopId` int NOT NULL,
  `imagePath` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `meter_readings` VALUES (1,'12345',100,'2024-09-10 10:34:56','user01',1,'/path/to/image1.jpg','2024-09-10 22:12:43','2024-09-10 22:12:43'),(2,'12345',100,'2024-09-10 10:34:56','user01',1,'/path/to/image1.jpg',NULL,NULL),(3,'12346',150,'2024-09-10 11:34:56','user02',2,'/path/to/image2.jpg',NULL,NULL),(4,'12347',200,'2024-09-10 12:34:56','user03',3,'/path/to/image3.jpg',NULL,NULL);
