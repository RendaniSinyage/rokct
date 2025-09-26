CREATE TABLE `shop_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint unsigned NOT NULL,
  `locale` varchar(255) NOT NULL,
  `title` varchar(191) NOT NULL,
  `description` mediumtext,
  `address` varchar(255) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `shop_translations_shop_id_locale_unique` (`shop_id`,`locale`),
  KEY `shop_translations_locale_index` (`locale`)
) ENGINE=InnoDB AUTO_INCREMENT=207 DEFAULT CHARSET=utf8mb3;

INSERT INTO `shop_translations` VALUES (72,512,'en','Debonairs (Musina)','Try Something amazing','Great North Road Plaza, Shop 35 Corner National Road &, Smelter Ave, Musina, 0900, South Africa',NULL),(78,511,'en','McDonalds (Musina)','“I\'m lovin\' it”','Messina, N1 National, Musina, 0900, South Africa',NULL),(84,509,'en','Axelgroup','Aircon Experts','South Africa, Musina, Limpopo',NULL),(90,510,'en','Boxer Liquors','Never Pay more than the Boxer Liquors Price','South Africa, Musina, Limpopo',NULL),(148,9012,'en','KFC MUSINA DRIVE THRU','Finger lickin good','KFC Musina 2, Cnr N1 &, Pat Harrison Road, Musina, South Africa','2024-07-24 19:13:15'),(152,9013,'en','South River','Refills at Home','3631 Mooketsi st, nancefield, musina, 0900','2024-06-08 22:22:16'),(153,9014,'en','South River','Refills at Home','3631 Mooketsi st, nancefield, musina, 0900','2024-07-02 14:14:37'),(169,504,'en','KFC MUSINA CBD','Finger lickin good','J2VM+72 Musina, South Africa',NULL),(172,505,'en','Nandos','Nando\'s PERi-PERi','Nando\'s Musina, Musina, South Africa',NULL),(173,9002,'en','Kota Too','Handful Gourmet Kotas','38 Riverside M-east, Thohoyandou-M, Thohoyandou, 0950, South Africa',NULL),(175,9001,'en','JuvoMart','Your online supermarket','3631 Mooketsi St, Messina-Nancefield, Musina, South Africa',NULL),(196,9000,'en','BWI Studios','Design Studio','BWI STUDIOS, Mooketsi Street, Musina, South Africa',NULL),(206,9003,'en','South River','Refills at Home','3631 Mooketsi st, nancefield, musina, 0900',NULL);
