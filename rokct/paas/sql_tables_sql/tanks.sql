CREATE TABLE `tanks` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint unsigned NOT NULL,
  `number` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` enum('raw','purified') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `capacity` decimal(10,2) NOT NULL,
  `status` enum('full','empty','halfEmpty','quarterEmpty') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `pump_status` json NOT NULL,
  `water_quality` json NOT NULL,
  `last_full` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tanks_shop_id_type_number_unique` (`shop_id`,`type`,`number`),
  CONSTRAINT `tanks_shop_id_foreign` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `tanks` VALUES (14,9003,'1','purified',4800.00,'full','{\"isOn\": false}','{\"ph\": 7.5, \"tds\": 16, \"hardness\": 0, \"temperature\": 25}','2025-02-15 13:09:21','2025-01-18 12:57:22','2025-02-15 13:09:21'),(20,9003,'1','raw',4800.00,'quarterEmpty','{\"isOn\": false}','{\"ph\": 7, \"tds\": 150, \"hardness\": 90, \"temperature\": 25}','2025-01-24 21:06:01','2025-01-21 22:17:48','2025-01-24 22:07:28');
