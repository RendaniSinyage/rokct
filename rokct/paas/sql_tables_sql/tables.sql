CREATE TABLE `tables` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `shop_section_id` bigint unsigned NOT NULL,
  `chair_count` smallint DEFAULT NULL,
  `tax` double DEFAULT '1',
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tables_shop_section_id_foreign` (`shop_section_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3;

INSERT INTO `tables` VALUES (1,'test',1,2,0,1,'2024-11-11 22:01:42','2024-11-11 22:01:42',NULL),(2,'test2',1,4,0,1,'2024-11-11 22:04:41','2024-11-11 22:04:41',NULL);
