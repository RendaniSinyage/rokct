CREATE TABLE `product_inventory_items` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `inventory_item_id` bigint unsigned NOT NULL,
  `product_id` bigint unsigned NOT NULL,
  `interval` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `product_inventory_items_inventory_item_id_foreign` (`inventory_item_id`),
  KEY `product_inventory_items_product_id_foreign` (`product_id`),
  CONSTRAINT `product_inventory_items_inventory_item_id_foreign` FOREIGN KEY (`inventory_item_id`) REFERENCES `inventory_items` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `product_inventory_items_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

