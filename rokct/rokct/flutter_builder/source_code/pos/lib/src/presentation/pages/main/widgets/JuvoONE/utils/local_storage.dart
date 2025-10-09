import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String USER_DATA_KEY = 'userData';

  static Future<void> setItem(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, json.encode(value));
    } catch (error) {
      print('Error setting SharedPreferences item: $error');
    }
  }

  static Future<dynamic> getItem(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final item = prefs.getString(key);
      return item != null ? json.decode(item) : null;
    } catch (error) {
      print('Error getting SharedPreferences item: $error');
      return null;
    }
  }

  static Future<void> removeItem(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (error) {
      print('Error removing SharedPreferences item: $error');
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (error) {
      print('Error clearing SharedPreferences: $error');
    }
  }

  static Future<void> setUserData(Map<String, dynamic> data) async {
    await setItem(USER_DATA_KEY, data);
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    return await getItem(USER_DATA_KEY);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final userData = await getUserData();
    return userData != null ? userData['user'] : null;
  }

  static Future<String?> getAccessToken() async {
    final userData = await getUserData();
    return userData != null ? userData['access_token'] : null;
  }

  static Future<Map<String, dynamic>?> getShopData() async {
    final user = await getUser();
    return user != null ? user['shop'] : null;
  }

  static Future<void> setShopData(Map<String, dynamic> shopData) async {
    final userData = await getUserData();
    if (userData != null && userData['user'] != null) {
      userData['user']['shop'] = shopData;
      await setUserData(userData);
    } else {
      print('Cannot set shop data: User data not found');
    }
  }

  static Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null;
  }

  static Future<void> clearUserData() async {
    await removeItem(USER_DATA_KEY);
  }

  static Future<void> updateUserData(Map<String, dynamic> newData) async {
    final currentData = await getUserData();
    if (currentData != null) {
      await setUserData({...currentData, ...newData});
    } else {
      await setUserData(newData);
    }
  }

  static Future<void> setToken(String token) async {
    final userData = await getUserData() ?? {};
    await setUserData({...userData, 'access_token': token});
  }

  static Future<void> removeToken() async {
    final userData = await getUserData();
    if (userData != null) {
      userData.remove('access_token');
      await setUserData(userData);
    }
  }
}
