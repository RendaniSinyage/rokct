CREATE TABLE `referral_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `referral_id` bigint unsigned NOT NULL,
  `title` varchar(255) NOT NULL,
  `locale` varchar(255) NOT NULL,
  `description` text,
  `faq` text,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `referral_translations_referral_id_locale_unique` (`referral_id`,`locale`),
  KEY `referral_translations_locale_index` (`locale`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb3;

INSERT INTO `referral_translations` VALUES (5,1,'R10 for you, R25 for a friend','en','Friends can get up to R25 off—you’ll get R10 when they place their first order.','Referral Terms and Conditions\nFor an Juvo user (or “Referrer”) to receive the referral reward stated in the user\'s account and for each new customer (each a “referral” or “Referee”) to receive the promotional offer, each new customer (“Referree”) must use the Referrer-provided promo code by the expiration date indicated in the Referrer’s account;
