CREATE TABLE `deliveryman_settings` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `type_of_technique` varchar(255) DEFAULT NULL,
  `brand` varchar(255) DEFAULT NULL,
  `model` varchar(255) DEFAULT NULL,
  `number` varchar(255) DEFAULT NULL,
  `color` varchar(255) DEFAULT NULL,
  `height` int DEFAULT NULL,
  `width` int DEFAULT NULL,
  `length` int DEFAULT NULL,
  `kg` int DEFAULT NULL,
  `online` tinyint(1) NOT NULL DEFAULT '0',
  `location` longtext,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `deliveryman_settings_user_id_unique` (`user_id`),
  CONSTRAINT `deliveryman_settings_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3;

INSERT INTO `deliveryman_settings` VALUES (1,106,'motorbike','BMW','Bike','4545','white',NULL,NULL,NULL,NULL,1,'{\"latitude\":-22.342385264868007,\"longitude\":30.016277228408626}','2023-04-08 10:16:12','2023-04-08 10:16:12',NULL),(2,137,'motorbike','BMW','Bike','4545','white',NULL,NULL,NULL,NULL,1,'{\"latitude\":-22.3443483,\"longitude\":30.0103283}','2023-04-21 07:58:46','2024-07-03 19:25:25',NULL),(3,868,'motorbike','Bigboy','Velocity150','13','white',1,NULL,NULL,20,1,'{\"latitude\":-22.3407861,\"longitude\":30.0138099}','2024-10-18 13:20:03','2025-06-30 13:22:52',NULL);
