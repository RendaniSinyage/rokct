CREATE TABLE `branch_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `branch_id` bigint unsigned NOT NULL,
  `title` varchar(255) DEFAULT NULL,
  `locale` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `branch_translations_branch_id_foreign` (`branch_id`),
  CONSTRAINT `branch_translations_branch_id_foreign` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

