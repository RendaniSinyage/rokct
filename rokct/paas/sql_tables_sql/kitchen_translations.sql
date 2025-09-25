CREATE TABLE `kitchen_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `kitchen_id` bigint unsigned NOT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `locale` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `kitchen_translations_kitchen_id_foreign` (`kitchen_id`),
  CONSTRAINT `kitchen_translations_kitchen_id_foreign` FOREIGN KEY (`kitchen_id`) REFERENCES `kitchens` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3;

INSERT INTO `kitchen_translations` VALUES (1,1,'Kitchen','Call store for get orders processed','en','2024-07-13 13:40:04','2024-07-13 13:40:04'),(2,2,'Kitchen1','test','en','2024-10-17 07:30:04','2024-10-17 07:30:04');
