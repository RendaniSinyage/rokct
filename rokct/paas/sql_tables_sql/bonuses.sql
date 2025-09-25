CREATE TABLE `bonuses` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint unsigned NOT NULL,
  `bonusable_type` varchar(255) NOT NULL,
  `bonusable_id` bigint unsigned NOT NULL,
  `bonus_quantity` int NOT NULL,
  `bonus_stock_id` bigint unsigned DEFAULT NULL,
  `value` int NOT NULL,
  `type` enum('count','sum') NOT NULL,
  `expired_at` datetime NOT NULL,
  `status` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `bonuses_shop_id_foreign` (`shop_id`),
  KEY `bonuses_bonusable_type_bonusable_id_index` (`bonusable_type`,`bonusable_id`),
  KEY `bonuses_bonusable_id_index` (`bonusable_id`),
  KEY `bonuses_bonusable_type_index` (`bonusable_type`),
  KEY `bonuses_bonus_stock_id_foreign` (`bonus_stock_id`),
  CONSTRAINT `bonuses_bonus_stock_id_foreign` FOREIGN KEY (`bonus_stock_id`) REFERENCES `stocks` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `bonuses_shop_id_foreign` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb3;

INSERT INTO `bonuses` VALUES (8,9003,'App\\Models\\Stock',281,1,281,1,'count','2024-08-01 00:00:00',1,'2024-07-04 14:24:01','2024-07-04 14:24:01',NULL);
