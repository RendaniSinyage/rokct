CREATE TABLE `extra_group_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `extra_group_id` bigint unsigned NOT NULL,
  `locale` varchar(255) NOT NULL,
  `title` varchar(191) NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `extra_group_translations_extra_group_id_locale_unique` (`extra_group_id`,`locale`),
  KEY `extra_group_translations_locale_index` (`locale`),
  CONSTRAINT `extra_group_translations_extra_group_id_foreign` FOREIGN KEY (`extra_group_id`) REFERENCES `extra_groups` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb3;

INSERT INTO `extra_group_translations` VALUES (1,1,'en','Size',NULL),(2,2,'en','Pack',NULL),(3,3,'en','Options',NULL),(4,4,'en','Level',NULL),(5,5,'en','Grade',NULL),(7,6,'en','Design Service',NULL),(8,7,'en','Compliance Options',NULL),(9,8,'en','Flavour',NULL),(10,9,'en','Amount',NULL),(11,10,'en','Temparature',NULL),(13,11,'en','Container Collection',NULL),(14,12,'en','Product',NULL),(15,13,'en','How d\'ya Like It?',NULL),(17,14,'en','Mielie Flavour',NULL);
