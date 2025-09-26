CREATE TABLE `chats` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `from_user_id` bigint unsigned NOT NULL,
  `to_user_id` bigint unsigned NOT NULL,
  `chat_message` varchar(255) DEFAULT NULL,
  `message_status` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `chats_from_user_id_foreign` (`from_user_id`),
  KEY `chats_to_user_id_foreign` (`to_user_id`),
  CONSTRAINT `chats_from_user_id_foreign` FOREIGN KEY (`from_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chats_to_user_id_foreign` FOREIGN KEY (`to_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

