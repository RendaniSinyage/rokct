CREATE TABLE `menu_products` (
  `menu_id` bigint unsigned NOT NULL,
  `product_id` bigint unsigned NOT NULL,
  KEY `menu_products_menu_id_foreign` (`menu_id`),
  KEY `menu_products_product_id_foreign` (`product_id`),
  CONSTRAINT `menu_products_menu_id_foreign` FOREIGN KEY (`menu_id`) REFERENCES `menus` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `menu_products_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

