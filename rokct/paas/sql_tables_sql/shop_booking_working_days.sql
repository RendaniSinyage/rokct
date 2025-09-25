CREATE TABLE `shop_booking_working_days` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint unsigned NOT NULL,
  `day` enum('monday','tuesday','wednesday','thursday','friday','saturday','sunday') NOT NULL,
  `from` varchar(5) NOT NULL DEFAULT '9-00',
  `to` varchar(5) NOT NULL DEFAULT '21-00',
  `disabled` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `shop_booking_working_days_shop_id_foreign` (`shop_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

