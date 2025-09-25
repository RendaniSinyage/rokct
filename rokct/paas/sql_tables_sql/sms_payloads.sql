CREATE TABLE `sms_payloads` (
  `type` varchar(255) NOT NULL DEFAULT 'firebase',
  `payload` longtext NOT NULL,
  `default` tinyint(1) NOT NULL DEFAULT '0',
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

INSERT INTO `sms_payloads` VALUES ('firebase','{\"default\":true,\"android_api_key\":\"AIzaSyCYp_cUJ7PuQyMem0LQZShw00yJpc_imyk\",\"api_key\":\"AIzaSyBtWjDrQdHtl628ZAQ1naWhPrsiidO18gg\",\"app_id\":\"1:728921419683:web:81a97b726ba3fa120db416\",\"auth_domain\":\"juvofood.firebaseapp.com\",\"ios_api_key\":\"AIzaSyBKk0rl3gKMzuVsKt0TAfAUY6yhlS2O3YU\",\"measurement_id\":\"G-PKYDE4B9DS\",\"message_sender_id\":\"728921419683\",\"project_id\":\"juvofood\",\"server_key\":\"AIzaSyACbWuYUg7UmWtuPODxAsuox5kOP0Ev1Tk\",\"storage_bucket\":\"juvofood.appspot.com\",\"vapid_key\":\"BB51fvOx-TryBXR0r7K0O_EM4zmXMXsPyjc1jfQsWnjLpJzM2CLgGhpsoWELvZby7hH7oyt1sSGkkb_uvzqEJEM\"}',1,NULL);
