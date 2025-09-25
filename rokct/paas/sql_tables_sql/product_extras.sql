CREATE TABLE `product_extras` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `product_id` bigint unsigned NOT NULL,
  `extra_group_id` bigint unsigned NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `product_extras_product_id_foreign` (`product_id`),
  KEY `product_extras_extra_group_id_foreign` (`extra_group_id`)
) ENGINE=InnoDB AUTO_INCREMENT=59 DEFAULT CHARSET=utf8mb3;

INSERT INTO `product_extras` VALUES (28,5,1,NULL),(29,5,11,NULL),(30,5,10,NULL),(32,67,9,NULL),(33,67,12,NULL),(34,193,3,NULL),(35,47,8,NULL),(36,195,8,NULL),(37,196,8,NULL),(38,197,8,NULL),(39,197,13,NULL),(40,204,8,NULL),(41,205,8,NULL),(42,205,13,NULL),(43,206,13,NULL),(44,212,8,NULL),(45,212,13,NULL),(46,212,14,NULL),(47,215,3,NULL),(48,215,8,NULL),(49,216,3,NULL),(50,216,8,NULL),(51,217,3,NULL),(52,217,8,NULL),(53,217,13,NULL),(58,65,10,NULL);
