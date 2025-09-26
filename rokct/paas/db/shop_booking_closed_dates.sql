CREATE TABLE `shop_booking_closed_dates` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint unsigned NOT NULL,
  `date` date NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `shop_booking_closed_dates_shop_id_foreign` (`shop_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

