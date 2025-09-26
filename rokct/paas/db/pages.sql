CREATE TABLE `pages` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `type` varchar(255) NOT NULL DEFAULT 'about',
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `img` varchar(255) DEFAULT NULL,
  `bg_img` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `buttons` longtext,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb3;

INSERT INTO `pages` VALUES (1,'about',0,'https://s3.juvo.app/public/images/receipts/101-1682063020.jpeg',NULL,'2023-04-21 05:45:05','2023-05-24 11:16:54','2023-05-24 11:16:54','[]'),(2,'about_second',0,'https://s3.juvo.app/public/images/receipts/101-1682063824.webp',NULL,'2023-04-21 05:57:08','2023-05-24 11:16:51','2023-05-24 11:16:51','{\"google_play_button_link\":\"https:\\/\\/play.google.com\\/store\\/apps\\/details?id=com.southriver.user\"}'),(3,'delivery',0,'https://s3.juvo.app/public/images/receipts/101-1682064018.webp',NULL,'2023-04-21 06:00:44','2023-05-24 11:16:47','2023-05-24 11:16:47','[]'),(4,'about_fourth',0,'https://s3.juvo.app/public/images/receipts/101-1682064088.webp',NULL,'2023-04-21 06:01:42','2023-05-24 11:16:44','2023-05-24 11:16:44','[]'),(6,'about_third',0,'https://s3.juvo.app/public/images/receipts/101-1682063824.webp',NULL,'2023-04-21 05:57:08','2023-05-24 11:16:40','2023-05-24 11:16:40','{\"google_play_button_link\":\"https:\\/\\/play.google.com\\/store\\/apps\\/details?id=com.southriver.user\"}'),(7,'about',1,'https://s3.juvo.app/public/images/receipts/101-1685827465.jpeg',NULL,'2023-06-03 19:24:30','2023-06-03 19:24:30',NULL,'[]'),(8,'delivery',1,'https://s3.juvo.app/public/images/receipts/101-1685828199.webp',NULL,'2023-06-03 19:39:47','2023-06-03 19:39:47',NULL,'[]'),(9,'about_second',1,'https://s3.juvo.app/public/images/receipts/101-1685828611.webp',NULL,'2023-06-03 19:43:34','2023-06-03 19:56:20',NULL,'{\"google_play_button_link\":\"https:\\/\\/play.google.com\\/store\\/apps\\/details?id=com.southriver.user\",\"app_store_button_link\":\"https:\\/\\/gosouth.app\\/\"}'),(10,'about_three',1,'https://s3.juvo.app/public/images/receipts/101-1685831143.webp',NULL,'2023-06-03 19:46:38','2023-06-03 20:25:49',NULL,'{\"google_play_button_link\":\"https:\\/\\/play.google.com\\/store\\/apps\\/details?id=com.southriver.vendor\",\"app_store_button_link\":\"#\"}'),(11,'about_fourth',1,'https://s3.juvo.app/public/images/receipts/101-1750273713.webp',NULL,'2023-06-03 19:49:57','2025-06-18 19:08:43',NULL,'{\"google_play_button_link\":\"https:\\/\\/play.google.com\\/store\\/apps\\/details?id=com.juvo.driver\",\"app_store_button_link\":\"#\"}');
