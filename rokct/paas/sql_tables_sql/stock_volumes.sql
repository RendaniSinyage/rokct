CREATE TABLE `stock_volumes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint unsigned NOT NULL,
  `stock_ids` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Comma-separated stock IDs',
  `volume` int NOT NULL COMMENT 'Volume in liters',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `stock_volumes_shop_id_stock_ids_unique` (`shop_id`,`stock_ids`),
  CONSTRAINT `stock_volumes_shop_id_foreign` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

