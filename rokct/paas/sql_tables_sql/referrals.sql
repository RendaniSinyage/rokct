CREATE TABLE `referrals` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `price_from` double DEFAULT NULL,
  `price_to` double DEFAULT NULL,
  `expired_at` datetime DEFAULT NULL,
  `img` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;

INSERT INTO `referrals` VALUES (1,10,25,'2025-05-31 23:59:59','https://s3.juvo.app/public/images/referral/101-1714650670.webp','2023-03-25 12:26:01','2024-05-02 11:52:28',NULL);
