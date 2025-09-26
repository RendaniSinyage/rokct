CREATE TABLE `email_settings` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `smtp_auth` tinyint(1) NOT NULL DEFAULT '1',
  `smtp_debug` tinyint(1) NOT NULL DEFAULT '0',
  `host` varchar(92) NOT NULL,
  `port` int NOT NULL DEFAULT '465',
  `password` varchar(255) DEFAULT NULL,
  `from_to` varchar(255) DEFAULT NULL,
  `from_site` varchar(255) DEFAULT NULL,
  `ssl` longtext,
  `active` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3;

INSERT INTO `email_settings` VALUES (3,1,0,'juvo.app',587,'Linkme78#@','no-reply@juvo.app','Juvo Platforms','{\"ssl\":{\"verify_peer\":false,\"verify_peer_name\":false,\"allow_self_signed\":true}}',1,'2024-07-30 11:26:01','2025-02-01 12:18:19',NULL);
