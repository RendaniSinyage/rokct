CREATE TABLE `card_types` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `card_types_name_unique` (`name`),
  UNIQUE KEY `card_types_code_unique` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `card_types` VALUES (1,'Visa','visa',1,NULL,NULL),(2,'Mastercard','mastercard',1,NULL,NULL),(3,'American Express','amex',1,NULL,NULL),(4,'Discover','discover',1,NULL,NULL),(5,'Diners Club','diners',1,NULL,NULL);
