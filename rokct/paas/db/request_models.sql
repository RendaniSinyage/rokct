CREATE TABLE `request_models` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `model_type` varchar(255) DEFAULT NULL,
  `model_id` bigint unsigned DEFAULT NULL,
  `created_by` bigint unsigned DEFAULT NULL,
  `data` longtext,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'pending',
  `status_note` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `request_models_model_type_model_id_index` (`model_type`,`model_id`),
  KEY `request_models_created_by_foreign` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

