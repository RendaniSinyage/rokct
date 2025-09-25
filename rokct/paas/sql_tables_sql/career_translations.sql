CREATE TABLE `career_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `career_id` bigint unsigned NOT NULL,
  `locale` varchar(255) NOT NULL,
  `title` varchar(191) NOT NULL,
  `description` text,
  `address` longtext,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `career_translations_career_id_locale_unique` (`career_id`,`locale`),
  KEY `career_translations_locale_index` (`locale`),
  CONSTRAINT `career_translations_career_id_foreign` FOREIGN KEY (`career_id`) REFERENCES `careers` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;

INSERT INTO `career_translations` VALUES (1,1,'en','Customer Success','<p>to be added</p>','\"Musina, South Africa\"',NULL);
