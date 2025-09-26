CREATE TABLE `privacy_policy_translations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `privacy_policy_id` bigint unsigned NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `locale` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `privacy_policy_translations_privacy_policy_id_locale_unique` (`privacy_policy_id`,`locale`),
  KEY `privacy_policy_translations_locale_index` (`locale`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;

INSERT INTO `privacy_policy_translations` VALUES (1,1,'PRIVACY POLICY','<h4><strong>INTRODUCTION</strong></h4><p>South River Technologies, and its owner, parent, subsidiary, and affiliated companies (“Company” or “We”) respect your privacy and are committed to protecting it through our compliance with this policy.</p><p>This policy describes the types of information we may collect from you or that you may provide when you visit the website/mobile app&nbsp;
