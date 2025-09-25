CREATE TABLE `sms_gateways` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(191) NOT NULL,
  `from` varchar(255) DEFAULT NULL,
  `type` varchar(255) NOT NULL,
  `api_key` varchar(255) DEFAULT NULL,
  `secret_key` varchar(255) DEFAULT NULL,
  `service_id` varchar(255) DEFAULT NULL,
  `text` varchar(191) DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

