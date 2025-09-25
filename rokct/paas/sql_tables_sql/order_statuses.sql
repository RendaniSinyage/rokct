CREATE TABLE `order_statuses` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `active` tinyint(1) NOT NULL,
  `sort` int NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb3;

INSERT INTO `order_statuses` VALUES (1,'new',1,1,NULL),(2,'accepted',1,2,NULL),(3,'ready',1,4,NULL),(4,'cooking',1,3,NULL),(5,'on_a_way',1,5,NULL),(6,'delivered',1,6,NULL),(7,'canceled',1,7,NULL);
