import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/app_config.dart';

class SecureStorageService {
  static SharedPreferences? _prefs;
  
  /// Initialize secure storage
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  /// Get SharedPreferences instance
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('SecureStorageService not initialized. Call initialize() first.');
    }
    return _prefs!;
  }

  // ===== AUTHENTICATION DATA =====
  
  /// Save auth token
  static Future<void> saveAuthToken(String token) async {
    await prefs.setString(AppConfig.authTokenKey, token);
  }
  
  /// Get auth token
  static String? getAuthToken() {
    return prefs.getString(AppConfig.authTokenKey);
  }
  
  /// Remove auth token
  static Future<void> removeAuthToken() async {
    await prefs.remove(AppConfig.authTokenKey);
  }
  
  /// Save user data
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await prefs.setString(AppConfig.userFullDataKey, json.encode(userData));
  }
  
  /// Get user data
  static Map<String, dynamic>? getUserData() {
    final userJson = prefs.getString(AppConfig.userFullDataKey);
    if (userJson != null) {
      return json.decode(userJson) as Map<String, dynamic>;
    }
    return null;
  }
  
  /// Remove user data
  static Future<void> removeUserData() async {
    await prefs.remove(AppConfig.userFullDataKey);
  }
  
  /// Save login state
  static Future<void> saveLoginState(bool isLoggedIn) async {
    await prefs.setBool(AppConfig.isLoggedInKey, isLoggedIn);
  }
  
  /// Get login state
  static bool getLoginState() {
    return prefs.getBool(AppConfig.isLoggedInKey) ?? false;
  }
  
  /// Remove login state
  static Future<void> removeLoginState() async {
    await prefs.remove(AppConfig.isLoggedInKey);
  }

  // ===== DAIRY BUSINESS DATA =====
  
  /// Save suppliers data
  static Future<void> saveSuppliersData(List<Map<String, dynamic>> suppliers) async {
    await prefs.setString('suppliers_data', json.encode(suppliers));
    await prefs.setString('suppliers_last_sync', DateTime.now().toIso8601String());
  }
  
  /// Get suppliers data
  static List<Map<String, dynamic>>? getSuppliersData() {
    final suppliersJson = prefs.getString('suppliers_data');
    if (suppliersJson != null) {
      final List<dynamic> decoded = json.decode(suppliersJson);
      return decoded.cast<Map<String, dynamic>>();
    }
    return null;
  }
  
  /// Get suppliers last sync time
  static DateTime? getSuppliersLastSync() {
    final lastSync = prefs.getString('suppliers_last_sync');
    if (lastSync != null) {
      return DateTime.parse(lastSync);
    }
    return null;
  }
  
  /// Save customers data
  static Future<void> saveCustomersData(List<Map<String, dynamic>> customers) async {
    await prefs.setString('customers_data', json.encode(customers));
    await prefs.setString('customers_last_sync', DateTime.now().toIso8601String());
  }
  
  /// Get customers data
  static List<Map<String, dynamic>>? getCustomersData() {
    final customersJson = prefs.getString('customers_data');
    if (customersJson != null) {
      final List<dynamic> decoded = json.decode(customersJson);
      return decoded.cast<Map<String, dynamic>>();
    }
    return null;
  }
  
  /// Get customers last sync time
  static DateTime? getCustomersLastSync() {
    final lastSync = prefs.getString('customers_last_sync');
    if (lastSync != null) {
      return DateTime.parse(lastSync);
    }
    return null;
  }
  
  /// Save milk collections data
  static Future<void> saveMilkCollectionsData(List<Map<String, dynamic>> collections) async {
    await prefs.setString('milk_collections_data', json.encode(collections));
    await prefs.setString('milk_collections_last_sync', DateTime.now().toIso8601String());
  }
  
  /// Get milk collections data
  static List<Map<String, dynamic>>? getMilkCollectionsData() {
    final collectionsJson = prefs.getString('milk_collections_data');
    if (collectionsJson != null) {
      final List<dynamic> decoded = json.decode(collectionsJson);
      return decoded.cast<Map<String, dynamic>>();
    }
    return null;
  }
  
  /// Get milk collections last sync time
  static DateTime? getMilkCollectionsLastSync() {
    final lastSync = prefs.getString('milk_collections_last_sync');
    if (lastSync != null) {
      return DateTime.parse(lastSync);
    }
    return null;
  }
  
  /// Save milk sales data
  static Future<void> saveMilkSalesData(List<Map<String, dynamic>> sales) async {
    await prefs.setString('milk_sales_data', json.encode(sales));
    await prefs.setString('milk_sales_last_sync', DateTime.now().toIso8601String());
  }
  
  /// Get milk sales data
  static List<Map<String, dynamic>>? getMilkSalesData() {
    final salesJson = prefs.getString('milk_sales_data');
    if (salesJson != null) {
      final List<dynamic> decoded = json.decode(salesJson);
      return decoded.cast<Map<String, dynamic>>();
    }
    return null;
  }
  
  /// Get milk sales last sync time
  static DateTime? getMilkSalesLastSync() {
    final lastSync = prefs.getString('milk_sales_last_sync');
    if (lastSync != null) {
      return DateTime.parse(lastSync);
    }
    return null;
  }

  // ===== APP CONFIGURATION =====
  
  /// Save app configuration
  static Future<void> saveAppConfig(Map<String, dynamic> config) async {
    await prefs.setString('app_config', json.encode(config));
  }
  
  /// Get app configuration
  static Map<String, dynamic>? getAppConfig() {
    final configJson = prefs.getString('app_config');
    if (configJson != null) {
      return json.decode(configJson) as Map<String, dynamic>;
    }
    return null;
  }
  
  /// Save user preferences
  static Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    await prefs.setString('user_preferences', json.encode(preferences));
  }
  
  /// Get user preferences
  static Map<String, dynamic>? getUserPreferences() {
    final prefsJson = prefs.getString('user_preferences');
    if (prefsJson != null) {
      return json.decode(prefsJson) as Map<String, dynamic>;
    }
    return null;
  }

  // ===== CACHE MANAGEMENT =====
  
  /// Clear all cached data
  static Future<void> clearAllCachedData() async {
    await prefs.remove('suppliers_data');
    await prefs.remove('suppliers_last_sync');
    await prefs.remove('customers_data');
    await prefs.remove('customers_last_sync');
    await prefs.remove('milk_collections_data');
    await prefs.remove('milk_collections_last_sync');
    await prefs.remove('milk_sales_data');
    await prefs.remove('milk_sales_last_sync');
    await prefs.remove('app_config');
    await prefs.remove('user_preferences');
  }
  
  /// Clear specific cache
  static Future<void> clearCache(String cacheKey) async {
    await prefs.remove(cacheKey);
    await prefs.remove('${cacheKey}_last_sync');
  }
  
  /// Check if cache is stale (older than specified duration)
  static bool isCacheStale(DateTime? lastSync, Duration maxAge) {
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > maxAge;
  }
  
  /// Get cache age
  static Duration? getCacheAge(DateTime? lastSync) {
    if (lastSync == null) return null;
    return DateTime.now().difference(lastSync);
  }
}
