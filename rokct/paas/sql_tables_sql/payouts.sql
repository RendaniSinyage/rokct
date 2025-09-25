CREATE TABLE `payouts` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `status` enum('pending','accepted','canceled') NOT NULL DEFAULT 'pending',
  `created_by` bigint unsigned DEFAULT NULL,
  `approved_by` bigint unsigned DEFAULT NULL,
  `currency_id` bigint unsigned DEFAULT NULL,
  `payment_id` bigint unsigned DEFAULT NULL,
  `cause` varchar(255) DEFAULT NULL,
  `answer` varchar(255) DEFAULT NULL,
  `price` double NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `payouts_created_by_foreign` (`created_by`),
  KEY `payouts_approved_by_foreign` (`approved_by`),
  KEY `payouts_currency_id_foreign` (`currency_id`),
  KEY `payouts_payment_id_foreign` (`payment_id`),
  CONSTRAINT `payouts_approved_by_foreign` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `payouts_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `payouts_currency_id_foreign` FOREIGN KEY (`currency_id`) REFERENCES `currencies` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `payouts_payment_id_foreign` FOREIGN KEY (`payment_id`) REFERENCES `payments` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;

INSERT INTO `payouts` VALUES (1,'pending',373,NULL,3,2,'test',NULL,100,'2024-04-01 08:21:50','2024-04-01 08:21:50',NULL);
