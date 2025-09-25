CREATE TABLE `user_memberships` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `membership_id` bigint unsigned NOT NULL,
  `start_date` datetime NOT NULL,
  `end_date` datetime NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_memberships_user_id_foreign` (`user_id`),
  KEY `user_memberships_membership_id_foreign` (`membership_id`),
  CONSTRAINT `user_memberships_membership_id_foreign` FOREIGN KEY (`membership_id`) REFERENCES `memberships` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_memberships_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `user_memberships` VALUES (1,147,2,'2025-05-19 14:14:18','2025-06-18 14:14:18',1,'2025-05-19 12:14:18','2025-05-19 12:14:18');
