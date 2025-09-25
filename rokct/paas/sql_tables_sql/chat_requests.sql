CREATE TABLE `chat_requests` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `from_user_id` int NOT NULL,
  `to_user_id` int NOT NULL,
  `status` enum('Pending','Approve','Reject') NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

