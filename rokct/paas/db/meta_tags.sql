CREATE TABLE `meta_tags` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `path` varchar(255) DEFAULT NULL,
  `model_id` int DEFAULT NULL,
  `model_type` varchar(255) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `keywords` varchar(255) DEFAULT NULL,
  `description` text,
  `h1` varchar(255) DEFAULT NULL,
  `seo_text` text,
  `canonical` varchar(255) DEFAULT NULL,
  `robots` varchar(255) DEFAULT NULL,
  `change_freq` varchar(10) DEFAULT NULL,
  `priority` varchar(10) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

