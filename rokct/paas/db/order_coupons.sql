CREATE TABLE `order_coupons` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `order_id` bigint unsigned NOT NULL,
  `user_id` bigint unsigned NOT NULL,
  `name` varchar(191) NOT NULL,
  `price` double DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `order_coupons_order_id_foreign` (`order_id`),
  CONSTRAINT `order_coupons_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb3;

INSERT INTO `order_coupons` VALUES (2,3222,241,'R5Off',5),(3,3224,241,'R10off',10),(4,3225,241,'R5Off',5),(5,3229,241,'R10off',10),(7,3413,829,'FREE25',25),(8,3555,831,'FREE25',25),(9,3659,801,'FREE25',25),(10,3692,148,'FREE25',25),(11,3693,875,'FREE25',25),(12,3731,852,'FREE25',25),(13,3732,148,'FREE25',25),(14,3856,148,'FREE25',25),(15,3928,883,'FREE25',25),(16,3935,859,'FREE25',25),(17,3943,801,'FREE25',25),(18,3950,801,'FREE25',25),(19,3954,758,'FREE25',25);
