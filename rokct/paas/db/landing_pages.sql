CREATE TABLE `landing_pages` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `type` varchar(255) NOT NULL,
  `data` longtext NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;

INSERT INTO `landing_pages` VALUES (1,'welcome','{\"title\":{\"en\":\"Water & Groceries, delivered!\"},\"description\":{\"en\":\"Choose your address and start ordering\"},\"img\":\"https:\\/\\/s3.juvo.app\\/public\\/images\\/languages\\/101-1750275705.webp\",\"features\":[{\"img\":\"https:\\/\\/s3.juvo.app\\/public\\/images\\/languages\\/101-1750275680.feature-1.mp4\",\"title\":{\"en\":\"Choose what you want\"},\"description\":{\"en\":\"Select items from your favorite stores at Juvo\"}},{\"img\":\"https:\\/\\/s3.juvo.app\\/public\\/images\\/languages\\/101-1750275684.feature-2.mp4\",\"title\":{\"en\":\"See real-time updates\"},\"description\":{\"en\":\"Personal shoppers pick items with care\"}},{\"img\":\"https:\\/\\/s3.juvo.app\\/public\\/images\\/languages\\/101-1750275690.feature-3.mp4\",\"title\":{\"en\":\"Get your items same-day\"},\"description\":{\"en\":\"Enjoy our 100% quality guarantee on every order\"}}]}','2023-06-03 19:15:10','2025-06-18 19:41:50',NULL);
