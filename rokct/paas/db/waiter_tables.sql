CREATE TABLE `waiter_tables` (
  `user_id` bigint unsigned NOT NULL,
  `table_id` bigint unsigned NOT NULL,
  KEY `waiter_tables_user_id_foreign` (`user_id`),
  KEY `waiter_tables_table_id_foreign` (`table_id`),
  CONSTRAINT `waiter_tables_table_id_foreign` FOREIGN KEY (`table_id`) REFERENCES `tables` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `waiter_tables_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `waiter_tables` VALUES (866,1);
