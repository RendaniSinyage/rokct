CREATE TABLE `tickets` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` char(36) NOT NULL,
  `created_by` bigint unsigned NOT NULL,
  `user_id` bigint DEFAULT NULL,
  `order_id` bigint DEFAULT NULL,
  `parent_id` bigint NOT NULL DEFAULT '0',
  `type` varchar(255) NOT NULL DEFAULT 'question',
  `subject` varchar(191) NOT NULL,
  `content` text NOT NULL,
  `status` enum('open','answered','progress','closed','rejected') NOT NULL DEFAULT 'open',
  `read` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tickets_created_by_foreign` (`created_by`),
  KEY `tickets_uuid_index` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

