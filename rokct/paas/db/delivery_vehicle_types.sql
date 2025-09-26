CREATE TABLE `delivery_vehicle_types` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `sort_order` int NOT NULL DEFAULT '0',
  `max_weight_kg` int DEFAULT NULL,
  `base_rate` decimal(8,2) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `delivery_vehicle_types_key_unique` (`key`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `delivery_vehicle_types` VALUES (1,'foot','On Foot','Walking delivery for very local orders',1,1,5,10.00,'2025-06-29 23:39:31','2025-06-29 23:39:31'),(2,'bike','Bicycle','Bicycle delivery for local orders',1,2,10,15.00,'2025-06-29 23:39:31','2025-06-29 23:39:31'),(3,'motorbike','Motorbike','Motorbike delivery for standard orders',1,3,20,25.00,'2025-06-29 23:39:31','2025-06-29 23:39:31'),(4,'benzine','Car (Petrol)','Petrol car for medium distance delivery',1,4,50,35.00,'2025-06-29 23:39:31','2025-06-29 23:39:31'),(5,'electric','Electric Vehicle','Electric car for eco-friendly delivery',1,5,50,30.00,'2025-06-29 23:39:31','2025-06-29 23:39:31'),(6,'hybrid','Hybrid Vehicle','Hybrid car for efficient delivery',1,6,50,32.00,'2025-06-29 23:39:31','2025-06-29 23:39:31'),(7,'diesel','Car (Diesel)','Diesel car for long distance delivery',1,7,60,40.00,'2025-06-29 23:39:31','2025-06-29 23:39:31'),(8,'gas','Gas Vehicle','Gas-powered vehicle for delivery',1,8,50,35.00,'2025-06-29 23:39:31','2025-06-29 23:39:31'),(9,'bakkie','Bakkie/Pickup','Small truck for medium agricultural loads',1,9,500,100.00,'2025-06-29 23:39:31','2025-06-29 23:39:31'),(10,'truck_small','Small Truck','Small truck for agricultural bulk delivery',1,10,1000,200.00,'2025-06-29 23:39:31','2025-06-29 23:39:31'),(11,'truck_medium','Medium Truck','Medium truck for large agricultural orders',1,11,3000,350.00,'2025-06-29 23:39:31','2025-06-29 23:39:31'),(12,'truck_large','Large Truck','Large truck for bulk wholesale orders',1,12,8000,500.00,'2025-06-29 23:39:31','2025-06-29 23:39:31');
