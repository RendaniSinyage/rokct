CREATE TABLE `receipts` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint unsigned NOT NULL,
  `category_id` bigint unsigned NOT NULL,
  `discount_type` tinyint(1) NOT NULL DEFAULT '0',
  `discount_price` double(8,2) NOT NULL DEFAULT '0.00',
  `img` varchar(255) DEFAULT NULL,
  `active_time` varchar(10) DEFAULT NULL,
  `total_time` varchar(10) DEFAULT NULL,
  `calories` int DEFAULT NULL,
  `servings` int DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `bg_img` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `receipts_shop_id_foreign` (`shop_id`),
  KEY `receipts_category_id_foreign` (`category_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

