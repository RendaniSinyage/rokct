CREATE TABLE `extra_groups` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `type` varchar(255) DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `shop_id` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `extra_groups_shop_id_foreign` (`shop_id`),
  CONSTRAINT `extra_groups_shop_id_foreign` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb3;

INSERT INTO `extra_groups` VALUES (1,'text',1,NULL,NULL),(2,'text',1,NULL,NULL),(3,'text',1,NULL,NULL),(4,'text',1,NULL,NULL),(5,'text',1,NULL,NULL),(6,'text',1,NULL,NULL),(7,'text',1,NULL,NULL),(8,'text',1,NULL,NULL),(9,'text',1,NULL,NULL),(10,'text',1,NULL,NULL),(11,'text',1,NULL,NULL),(12,'text',1,NULL,9003),(13,'text',1,NULL,505),(14,'text',1,NULL,505);
