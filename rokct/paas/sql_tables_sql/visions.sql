CREATE TABLE `visions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `shop_id` bigint unsigned DEFAULT NULL,
  `statement` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `effective_date` date NOT NULL,
  `end_date` date DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `visions_uuid_unique` (`uuid`),
  KEY `visions_shop_id_foreign` (`shop_id`),
  CONSTRAINT `visions_shop_id_foreign` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `visions` VALUES (1,'63f1e6ac-bced-4b77-a460-7124372403ea',9003,'Innovative Tech for Clean, Affordable Water, Building a sustainable hydration netwrk accross africa.','2025-05-19',NULL,1,147,'2025-05-19 12:31:36','2025-05-19 12:31:36','2025-05-19 13:15:19'),(2,'0e622db9-6465-4f5b-8903-197a0ada8290',9003,'Innovative Tech for Clean, Affordable Water, Building a sustainable hydration netwrk accross africa.','2025-05-19',NULL,1,147,'2025-05-19 13:36:19','2025-05-19 13:36:19',NULL),(3,'93da0ddc-ea89-451e-bf72-a086778939b8',NULL,'test','2025-05-19',NULL,1,101,'2025-05-19 13:37:55','2025-05-19 13:37:55',NULL);
