CREATE TABLE `brands` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `slug` varchar(255) DEFAULT NULL,
  `uuid` char(36) NOT NULL,
  `title` varchar(255) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `img` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `shop_id` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `brands_uuid_index` (`uuid`),
  KEY `brands_shop_id_foreign` (`shop_id`),
  CONSTRAINT `brands_shop_id_foreign` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb3;

INSERT INTO `brands` VALUES (1,NULL,'b06ab787-b3e7-4c77-8848-3401936046f1','SouthRiver',1,NULL,'2023-03-09 14:29:11','2024-03-30 21:51:26',NULL,NULL),(2,NULL,'83c630a2-2b08-4ae0-bdda-64b1de79e339','no brand',1,NULL,'2023-03-09 14:29:20','2024-04-30 11:37:53',NULL,NULL),(3,NULL,'ab90c8d9-a655-4ee8-8031-29ee466f7bb1','private label',1,NULL,'2023-03-09 14:29:37','2023-03-09 14:29:37',NULL,NULL),(4,NULL,'b21b0f4d-a300-47b5-8aba-509801ca2321','Sunbake',1,'https://s3.juvo.app/public/images/brands/108-1678416782.webp','2023-03-10 02:53:20','2023-03-10 02:53:20',NULL,NULL),(5,NULL,'86aafadb-f5e9-4e4e-8f48-cfb297a615c3','Blue Ribbon',1,'https://s3.juvo.app/public/images/brands/108-1678416867.webp','2023-03-10 02:54:41','2023-03-10 02:54:41',NULL,NULL),(6,NULL,'3f5d2895-7af4-473c-9662-1a86a81b15ad','Coca-Cola',1,NULL,'2023-03-29 09:29:19','2024-03-24 18:04:43',NULL,NULL);
