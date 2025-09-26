CREATE TABLE `email_templates` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `email_setting_id` bigint unsigned NOT NULL,
  `subject` varchar(255) NOT NULL,
  `body` text NOT NULL,
  `alt_body` text NOT NULL,
  `status` tinyint NOT NULL,
  `send_to` datetime NOT NULL,
  `type` varchar(50) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `email_templates_email_setting_id_foreign` (`email_setting_id`),
  CONSTRAINT `email_templates_email_setting_id_foreign` FOREIGN KEY (`email_setting_id`) REFERENCES `email_settings` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb3;

INSERT INTO `email_templates` VALUES (1,3,'testing','<p>tester</p>','test',0,'2024-08-27 13:33:40','subscribe','2024-08-27 08:32:20','2025-02-01 13:31:18','2025-02-01 13:31:18'),(4,3,'testing','<p>test</p>','test',1,'2025-02-01 15:31:47','subscribe','2025-02-01 13:31:51','2025-02-01 13:31:51',NULL);
