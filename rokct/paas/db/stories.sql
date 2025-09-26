CREATE TABLE `stories` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `product_id` bigint unsigned NOT NULL,
  `shop_id` bigint unsigned NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `file_urls` longtext,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `stories_product_id_foreign` (`product_id`),
  KEY `stories_shop_id_foreign` (`shop_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

