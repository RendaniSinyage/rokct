CREATE TABLE `combo_stocks` (
  `combo_id` bigint unsigned NOT NULL,
  `stock_id` bigint unsigned NOT NULL,
  KEY `combo_stocks_combo_id_foreign` (`combo_id`),
  KEY `combo_stocks_stock_id_foreign` (`stock_id`),
  CONSTRAINT `combo_stocks_combo_id_foreign` FOREIGN KEY (`combo_id`) REFERENCES `combos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `combo_stocks_stock_id_foreign` FOREIGN KEY (`stock_id`) REFERENCES `stocks` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

