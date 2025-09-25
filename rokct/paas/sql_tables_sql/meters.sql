CREATE TABLE `meters` (
  `id` int NOT NULL AUTO_INCREMENT,
  `number` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `shop_id` bigint unsigned DEFAULT NULL,
  `type` enum('electricity','water') NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `number` (`number`),
  KEY `fk_meters_shop` (`shop_id`),
  CONSTRAINT `fk_meters_shop` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3;

INSERT INTO `meters` VALUES (1,'04289039804','2024-10-26 13:20:52','2024-10-26 14:11:45',9003,'electricity');
