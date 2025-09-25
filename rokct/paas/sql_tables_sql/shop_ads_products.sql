CREATE TABLE `shop_ads_products` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `shop_ads_package_id` bigint unsigned NOT NULL,
  `product_id` bigint unsigned NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `shop_ads_products_shop_ads_package_id_foreign` (`shop_ads_package_id`),
  KEY `shop_ads_products_product_id_foreign` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

