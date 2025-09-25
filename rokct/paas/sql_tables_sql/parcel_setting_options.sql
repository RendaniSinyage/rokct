CREATE TABLE `parcel_setting_options` (
  `parcel_option_id` bigint unsigned NOT NULL,
  `parcel_order_setting_id` bigint unsigned NOT NULL,
  KEY `parcel_setting_options_parcel_option_id_foreign` (`parcel_option_id`),
  KEY `parcel_setting_options_parcel_order_setting_id_foreign` (`parcel_order_setting_id`),
  CONSTRAINT `parcel_setting_options_parcel_option_id_foreign` FOREIGN KEY (`parcel_option_id`) REFERENCES `parcel_options` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `parcel_setting_options_parcel_order_setting_id_foreign` FOREIGN KEY (`parcel_order_setting_id`) REFERENCES `parcel_order_settings` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

