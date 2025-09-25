CREATE TABLE `weather_data` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `city_name` varchar(255) NOT NULL,
  `country_code` varchar(2) NOT NULL,
  `request_count` int unsigned DEFAULT '0',
  `last_fetched_at` timestamp NULL DEFAULT NULL,
  `last_request_at` timestamp NULL DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_city` (`city_name`,`country_code`),
  UNIQUE KEY `weather_data_city_name_country_code_unique` (`city_name`,`country_code`),
  KEY `idx_last_fetched` (`last_fetched_at`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB AUTO_INCREMENT=15237 DEFAULT CHARSET=utf8mb3;

INSERT INTO `weather_data` VALUES (15235,'messina','za',127,'2025-08-28 08:19:14','2025-08-28 08:19:14',1,'2025-06-15 22:39:21','2025-08-28 08:19:14'),(15236,'musina','za',14,'2025-08-26 19:08:11','2025-08-26 19:08:11',1,'2025-06-17 09:35:43','2025-08-26 19:08:11');
