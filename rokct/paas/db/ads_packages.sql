CREATE TABLE `ads_packages` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `active` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Активный',
  `input` smallint NOT NULL DEFAULT '1' COMMENT 'Где будет выходить',
  `position_page` smallint NOT NULL DEFAULT '1' COMMENT 'На какой странице будет выходить',
  `time_type` varchar(255) NOT NULL DEFAULT 'day' COMMENT 'Тип времени рекламы: минут,час,день,недель,месяц,год',
  `time` smallint NOT NULL COMMENT 'Время',
  `price` double NOT NULL DEFAULT '0',
  `product_limit` smallint DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `banner_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ads_packages_banner_id_foreign` (`banner_id`),
  CONSTRAINT `ads_packages_banner_id_foreign` FOREIGN KEY (`banner_id`) REFERENCES `banners` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb3;

INSERT INTO `ads_packages` VALUES (15,1,1,1,'year',22,10,NULL,'2024-04-29 13:10:42','2023-08-11 14:57:01','2024-04-29 13:10:42',10),(16,1,1,1,'year',22,10,NULL,NULL,'2024-04-24 11:34:55','2024-08-05 19:26:25',13),(17,1,1,1,'year',22,10,NULL,NULL,'2024-04-29 13:11:37','2024-08-05 19:31:07',15);
