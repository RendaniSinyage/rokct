CREATE TABLE `expenses_type` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb3;

INSERT INTO `expenses_type` VALUES (1,'energy','2024-10-26 13:09:16','2024-10-26 13:09:16'),(2,'expense','2024-10-26 13:09:16','2024-10-26 13:09:16'),(3,'fuel','2024-10-26 13:09:16','2024-10-26 13:09:16'),(4,'cost of sale','2024-10-26 13:59:39','2024-10-26 13:59:39');
