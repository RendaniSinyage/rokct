CREATE TABLE `receipt_stocks` (
  `receipt_id` bigint unsigned NOT NULL,
  `stock_id` bigint unsigned NOT NULL,
  `min_quantity` int NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  KEY `receipt_stocks_receipt_id_foreign` (`receipt_id`),
  KEY `receipt_stocks_stock_id_foreign` (`stock_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

