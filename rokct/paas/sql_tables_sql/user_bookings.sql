CREATE TABLE `user_bookings` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `booking_id` bigint unsigned NOT NULL,
  `user_id` bigint unsigned DEFAULT NULL,
  `table_id` bigint unsigned NOT NULL,
  `start_date` datetime DEFAULT NULL,
  `end_date` datetime DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'new',
  `note` varchar(255) DEFAULT NULL,
  `guest` smallint DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_bookings_booking_id_foreign` (`booking_id`),
  KEY `user_bookings_table_id_foreign` (`table_id`),
  KEY `user_bookings_user_id_foreign` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

