CREATE TABLE `assign_shop_tags` (
  `shop_tag_id` bigint unsigned NOT NULL,
  `shop_id` bigint unsigned NOT NULL,
  KEY `assign_shop_tags_shop_tag_id_foreign` (`shop_tag_id`),
  KEY `assign_shop_tags_shop_id_foreign` (`shop_id`),
  CONSTRAINT `assign_shop_tags_shop_id_foreign` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `assign_shop_tags_shop_tag_id_foreign` FOREIGN KEY (`shop_tag_id`) REFERENCES `shop_tags` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

INSERT INTO `assign_shop_tags` VALUES (5,9001),(4,9001),(5,9003),(5,505),(4,505),(5,504),(5,9000),(3,9003),(5,9002);
