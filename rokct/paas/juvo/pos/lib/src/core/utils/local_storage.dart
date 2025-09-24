import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/data/location_data.dart';
import '../../models/models.dart';
import '../constants/constants.dart';

class LocalStorage {
  static SharedPreferences? _preferences;

  LocalStorage._();

  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // Float and shift management methods
  static Future<bool> setDouble(String key, double value) async {
    if (_preferences != null) {
      return await _preferences!.setDouble(key, value);
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.setDouble(key, value);
  }

  static double? getDouble(String key) {
    if (_preferences != null) {
      return _preferences!.getDouble(key);
    }
    return 0.0;
  }

  static Future<void> setFloatAmount(double amount) async {
    await setDouble('float_amount', amount);
    final now = DateTime.now();
    await _preferences?.setString('float_date',
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}");
    await _preferences?.setBool('shift_open', true);
  }

  static double getFloatAmount() {
    return getDouble('float_amount') ?? 0.0;
  }

  static bool isShiftOpen() {
    return _preferences?.getBool('shift_open') ?? false;
  }

  static String? getFloatDate() {
    return _preferences?.getString('float_date');
  }

  static bool needsToCloseShift() {
    final floatDateStr = getFloatDate();
    if (floatDateStr == null) return false;

    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final isNewDay = floatDateStr != todayStr;

    return isNewDay && isShiftOpen() && getFloatAmount() > 0;
  }

  static Future<void> closeShift() async {
    await _preferences?.setDouble('float_amount', 0.0);
    await _preferences?.remove('float_date');
    await _preferences?.setBool('shift_open', false);
  }

  // Language and translation methods
  static Future<void> setOtherTranslations({
    required Map<String, dynamic>? translations,
    required String key
  }) async {
    SharedPreferences? local = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(translations);
    await local.setString(key, encoded);
  }

  static Future<Map<String, dynamic>> getOtherTranslations({
    required String key
  }) async {
    SharedPreferences? local = await SharedPreferences.getInstance();
    final String encoded = local.getString(key) ?? '';
    if (encoded.isEmpty) {
      return {};
    }
    final Map<String, dynamic> decoded = jsonDecode(encoded);
    return decoded;
  }

  static Future<void> setSystemLanguage(LanguageData? lang) async {
    if (_preferences != null) {
      final String langString = jsonEncode(lang?.toJson());
      await _preferences!.setString(StorageKeys.keySystemLanguage, langString);
    }
  }

  static LanguageData? getSystemLanguage() {
    final lang = _preferences?.getString(StorageKeys.keySystemLanguage);
    if (lang == null) return null;
    final map = jsonDecode(lang);
    if (map == null) return null;
    return LanguageData.fromJson(map);
  }

  static Future<void> setLanguageData(LanguageData? langData) async {
    final String lang = jsonEncode(langData?.toJson());
    setLangLtr(langData?.backward);
    await _preferences?.setString(StorageKeys.keyLanguageData, lang);
  }

  static LanguageData? getLanguage() {
    final lang = _preferences?.getString(StorageKeys.keyLanguageData);
    if (lang == null) return null;
    final map = jsonDecode(lang);
    if (map == null) return null;
    return LanguageData.fromJson(map);
  }

  static bool getLangLtr() =>
      !(_preferences?.getBool(StorageKeys.keyLangLtr) ?? true);

  static Future<void> setLangLtr(bool? backward) async {
    if (_preferences != null) {
      await _preferences?.setBool(StorageKeys.keyLangLtr, backward ?? false);
    }
  }

  // Authentication methods
  static Future<void> setToken(String? token) async {
    if (_preferences != null) {
      await _preferences!.setString(StorageKeys.keyToken, token ?? '');
    }
  }

  static String getToken() =>
      _preferences?.getString(StorageKeys.keyToken) ?? '';

  static void deleteToken() =>
      _preferences?.remove(StorageKeys.keyToken);

  static Future<void> setPinCode(String pinCode) async {
    if (_preferences != null) {
      await _preferences!.setString(StorageKeys.pinCode, pinCode);
    }
  }

  static String getPinCode() =>
      _preferences?.getString(StorageKeys.pinCode) ?? '';

  static void deletePinCode() =>
      _preferences?.remove(StorageKeys.pinCode);

  // Settings methods
  static Future<void> setSettingsList(List<SettingsData> settings) async {
    if (_preferences != null) {
      final List<String> strings =
      settings.map((setting) => jsonEncode(setting.toJson())).toList();
      await _preferences!.setStringList(StorageKeys.keyGlobalSettings, strings);
    }
  }

  static List<SettingsData> getSettingsList() {
    final List<String> settings =
        _preferences?.getStringList(StorageKeys.keyGlobalSettings) ?? [];
    final List<SettingsData> settingsList = settings
        .map((setting) => SettingsData.fromJson(jsonDecode(setting)))
        .toList();
    return settingsList;
  }

  static void deleteSettingsList() =>
      _preferences?.remove(StorageKeys.keyGlobalSettings);

  // Locale and translation methods
  static Future<void> setActiveLocale(String? locale) async {
    if (_preferences != null) {
      await _preferences!.setString(StorageKeys.keyActiveLocale, locale ?? '');
    }
  }

  static void deleteActiveLocale() =>
      _preferences?.remove(StorageKeys.keyActiveLocale);

  static Future<void> setTranslations(Map<String, dynamic>? translations) async {
    if (_preferences != null) {
      final String encoded = jsonEncode(translations);
      await _preferences!.setString(StorageKeys.keyTranslations, encoded);
    }
  }

  static Map<String, dynamic> getTranslations() {
    final String encoded =
        _preferences?.getString(StorageKeys.keyTranslations) ?? '';
    if (encoded.isEmpty) {
      return {};
    }
    return jsonDecode(encoded);
  }

  static void deleteTranslations() =>
      _preferences?.remove(StorageKeys.keyTranslations);

  // Currency methods
  static Future<void> setSelectedCurrency(CurrencyData currency) async {
    if (_preferences != null) {
      final String currencyString = jsonEncode(currency.toJson());
      await _preferences!.setString(StorageKeys.keySelectedCurrency, currencyString);
    }
  }

  static CurrencyData getSelectedCurrency() {
    final map = jsonDecode(
        _preferences?.getString(StorageKeys.keySelectedCurrency) ?? '');
    return CurrencyData.fromJson(map);
  }

  static void deleteSelectedCurrency() =>
      _preferences?.remove(StorageKeys.keySelectedCurrency);

  // Shopping bag methods
  static Future<void> setBags(List<BagData> bags) async {
    if (_preferences != null) {
      try {
        final List<String> strings =
        bags.map((bag) => jsonEncode(bag.toJson())).toList();
        await _preferences!.setStringList(StorageKeys.keyBags, strings);
        if (kDebugMode) {
          if (kDebugMode) {
            print('Bags saved successfully: ${bags.length} items');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error saving bags: $e');
        }
      }
    } else {
      if (kDebugMode) {
        print('SharedPreferences not initialized');
      }
    }
  }

  static List<BagData> getBags() {
    try {
      final List<String> bags =
          _preferences?.getStringList(StorageKeys.keyBags) ?? [];
      final List<BagData> localBags = bags
          .map((bag) => BagData.fromJson(jsonDecode(bag)))
          .toList(growable: true);
      if (kDebugMode) {
        print('Bags retrieved successfully: ${localBags.length} items');
      }
      return localBags;
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving bags: $e');
      }
      return [];
    }
  }

  static void deleteCartProducts() =>
      _preferences?.remove(StorageKeys.keyBags);

  // User and shop data methods
  static Future<void> setUser(UserData? user) async {
    if (_preferences != null) {
      final String userString = user != null ? jsonEncode(user.toJson()) : '';
      await _preferences!.setString(StorageKeys.keyUser, userString);
    }
  }

  static UserData? getUser() {
    final savedString = _preferences?.getString(StorageKeys.keyUser);
    if (savedString == null) return null;
    final map = jsonDecode(savedString);
    if (map == null) return null;
    return UserData.fromJson(map);
  }

  static void deleteUser() =>
      _preferences?.remove(StorageKeys.keyUser);

  static Future<void> setShopData(ShopData shopData) async {
    if (_preferences != null) {
      final String shopDataString = jsonEncode(shopData.toJson());
      await _preferences!.setString(AppConstants.keyShopData, shopDataString);
    }
  }

  static ShopData? getShopData() {
    final shopDataString = _preferences?.getString(AppConstants.keyShopData);
    if (shopDataString == null) return null;
    final map = jsonDecode(shopDataString);
    if (map == null) return null;
    return ShopData.fromJson(map);
  }

  // Shop Location methods
  static Future<void> setShopLocation(LocationData? location) async {
    if (_preferences != null && location != null) {
      final locationMap = location.toJson();
      final String locationString = jsonEncode(locationMap);
      await _preferences!.setString('shop_location', locationString);
    }
  }

  static LocationData? getShopLocation() {
    final locationString = _preferences?.getString('shop_location');
    if (locationString == null) return null;

    try {
      final map = jsonDecode(locationString);
      return LocationData.fromJson(map);
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving shop location: $e');
      }
      return null;
    }
  }

  static Future<void> saveUserShopLocation(UserData? userData) async {
    if (userData?.shop?.location != null) {
      final location = LocationData(
          latitude: double.tryParse(userData!.shop!.location!.latitude ?? ''),
          longitude: double.tryParse(userData.shop!.location!.longitude ?? '')
      );
      await setShopLocation(location);
    }
  }

  static void clearShopLocation() {
    _preferences?.remove('shop_location');
  }

  // Yoco payment methods
  static Future<void> setYocoKeys({
    required String publicKey,
    required String privateKey,
    required bool isTest,
  }) async {
    if (_preferences != null) {
      await _preferences!.setString(AppConstants.YOCO_PUBLIC_KEY, publicKey);
      await _preferences!.setString(AppConstants.YOCO_PRIVATE_KEY, privateKey);
      await _preferences!.setString(AppConstants.YOCO_ENVIRONMENT, isTest ? 'test' : 'live');
    }
  }

  static String? getYocoPublicKey() =>
      _preferences?.getString(AppConstants.YOCO_PUBLIC_KEY);

  static String? getYocoPrivateKey() =>
      _preferences?.getString(AppConstants.YOCO_PRIVATE_KEY);

  static bool isYocoTest() =>
      _preferences?.getString(AppConstants.YOCO_ENVIRONMENT) == 'test';

  static Future<void> setYocoPairedDevice(String deviceId) async {
    if (_preferences != null) {
      await _preferences!.setString(AppConstants.YOCO_PAIRED_DEVICE, deviceId);
    }
  }

  static String? getYocoPairedDevice() =>
      _preferences?.getString(AppConstants.YOCO_PAIRED_DEVICE);

  static bool hasYocoCredentials() {
    bool hasEnvironment = _preferences?.getString(AppConstants.YOCO_ENVIRONMENT) != null;
    bool hasPublicKey = getYocoPublicKey()?.isNotEmpty ?? false;
    return hasEnvironment && hasPublicKey;
  }


  static Future<void> setString(String key, String value) async {
    await _preferences?.setString(key, value);
  }

  static String? getString(String key) {
    return _preferences?.getString(key);
  }

  static Future<void> remove(String key) async {
    await _preferences?.remove(key);
  }

  static Future<void> clear() async {
    await _preferences?.clear();
  }

  ///Maintenance Progress
  static Future<void> setItem(String key, String value) async {
    if (_preferences != null) {
      await _preferences!.setString(key, value);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    }
  }

  static Future<String?> getItem(String key) async {
    if (_preferences != null) {
      return _preferences!.getString(key);
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> removeItem(String key) async {
    if (_preferences != null) {
      await _preferences!.remove(key);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    }
  }

  // Clear all data
  static void clearStore() {
    deletePinCode();
    deleteToken();
    deleteUser();
    deleteCartProducts();
    clearShopLocation();
    _preferences?.remove('float_amount');
    _preferences?.remove('float_date');
    _preferences?.remove('shift_open');
    _preferences?.remove('weather_cache');

    // Clear all city name cache entries
    final allKeys = _preferences?.getKeys() ?? {};
    for (final key in allKeys) {
      if (key.startsWith('city_cache_')) {
        _preferences?.remove(key);
      }
    }

    // Clear maintenance progress keys
    for (final key in allKeys) {
      if (key.startsWith('maintenance_progress_')) {
        _preferences?.remove(key);
      }
    }
  }
}
