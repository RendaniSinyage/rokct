CREATE TABLE `stock_inventory_items` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `inventory_item_id` bigint unsigned NOT NULL,
  `stock_id` bigint unsigned NOT NULL,
  `interval` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `stock_inventory_items_inventory_item_id_foreign` (`inventory_item_id`),
  KEY `stock_inventory_items_stock_id_foreign` (`stock_id`),
  CONSTRAINT `stock_inventory_items_inventory_item_id_foreign` FOREIGN KEY (`inventory_item_id`) REFERENCES `inventory_items` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `stock_inventory_items_stock_id_foreign` FOREIGN KEY (`stock_id`) REFERENCES `stocks` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

