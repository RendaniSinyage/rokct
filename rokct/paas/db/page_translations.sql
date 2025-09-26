CREATE TABLE `page_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `page_id` bigint unsigned NOT NULL,
  `locale` varchar(255) NOT NULL,
  `title` varchar(191) NOT NULL,
  `description` text,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `page_translations_page_id_locale_unique` (`page_id`,`locale`),
  KEY `page_translations_locale_index` (`locale`),
  CONSTRAINT `page_translations_page_id_foreign` FOREIGN KEY (`page_id`) REFERENCES `pages` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb3;

INSERT INTO `page_translations` VALUES (6,1,'en','About GOsouth','\"<p>Tens of millions of people look for design inspiration and feedback on Dribbble. We help players like you share small screenshots (shots) to show off your current projects, boost your portfolio, and love what you do\\u2014no matter what kind of creative professional you are. Founded in 2009, we are a bootstrapped and profitable company helping design talent share, grow, and get hired by over 40,000 of today\\u2019s most innovative brands around the world.<\\/p>\"',NULL),(7,2,'en','Water and Grocery customer app','\"<p>Instead of traditional food delivery jobs where the hours aren\\u2019t flexible, try being your own boss with Foodyman. Get paid to deliver on your schedule using the food delivery app most downloaded by customers.<\\/p>\"',NULL),(8,3,'en','Become a deliveryman','\"<p>about<\\/p>\"',NULL),(10,4,'en','Manager App','\"<p>about<\\/p>\"',NULL),(14,8,'en','Looking for delivery driver jobs?','\"<p>Are you looking for a flexible and rewarding opportunity? Join our team as a delivery partner and become an essential part of connecting hungry customers with their favorites from local restaurants &amp;
