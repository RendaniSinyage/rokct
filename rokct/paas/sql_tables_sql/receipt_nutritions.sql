CREATE TABLE `receipt_nutritions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `receipt_id` bigint unsigned NOT NULL,
  `weight` varchar(10) NOT NULL,
  `percentage` tinyint NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `receipt_nutritions_receipt_id_foreign` (`receipt_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

