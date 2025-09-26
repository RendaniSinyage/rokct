CREATE TABLE `shop_deliveryman_settings` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint unsigned NOT NULL,
  `type` enum('fix','percent') NOT NULL,
  `value` int NOT NULL,
  `period` smallint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `shop_deliveryman_settings_shop_id_foreign` (`shop_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

