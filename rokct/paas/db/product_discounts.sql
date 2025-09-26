CREATE TABLE `product_discounts` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `product_id` bigint unsigned NOT NULL,
  `discount_id` bigint unsigned NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `product_discounts_product_id_foreign` (`product_id`),
  KEY `product_discounts_discount_id_foreign` (`discount_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

