CREATE TABLE `business_projections` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `shop_id` bigint unsigned DEFAULT NULL,
  `year` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sales_projection` decimal(15,2) DEFAULT NULL,
  `jobs_projection` int DEFAULT NULL,
  `other_metric_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `other_metric_value` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `business_projections_uuid_unique` (`uuid`),
  KEY `business_projections_shop_id_foreign` (`shop_id`),
  CONSTRAINT `business_projections_shop_id_foreign` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

