import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for storing and retrieving local data (before API integration)
/// This preserves posted data so it appears as if connected to APIs
class LocalDataService {
  static SharedPreferences? _prefs;

  /// Initialize local storage
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('LocalDataService not initialized. Call initialize() first.');
    }
    return _prefs!;
  }

  // ===== COLLECTIONS DATA =====
  
  /// Save a collection locally
  static Future<void> saveCollection(Map<String, dynamic> collection) async {
    final collections = getCollections();
    collections.add({
      ...collection,
      'id': collection['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'created_at': collection['created_at'] ?? DateTime.now().toIso8601String(),
    });
    await prefs.setString('local_collections', json.encode(collections));
  }

  /// Get all collections
  static List<Map<String, dynamic>> getCollections() {
    final collectionsJson = prefs.getString('local_collections');
    if (collectionsJson != null) {
      final List<dynamic> decoded = json.decode(collectionsJson);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Update a collection
  static Future<void> updateCollection(String id, Map<String, dynamic> updates) async {
    final collections = getCollections();
    final index = collections.indexWhere((c) => c['id'] == id);
    if (index != -1) {
      collections[index] = {
        ...collections[index],
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await prefs.setString('local_collections', json.encode(collections));
    }
  }

  /// Delete a collection
  static Future<void> deleteCollection(String id) async {
    final collections = getCollections();
    collections.removeWhere((c) => c['id'] == id);
    await prefs.setString('local_collections', json.encode(collections));
  }

  // ===== SALES DATA =====
  
  /// Save a sale locally
  static Future<void> saveSale(Map<String, dynamic> sale) async {
    final sales = getSales();
    sales.add({
      ...sale,
      'id': sale['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'created_at': sale['created_at'] ?? DateTime.now().toIso8601String(),
    });
    await prefs.setString('local_sales', json.encode(sales));
  }

  /// Get all sales
  static List<Map<String, dynamic>> getSales() {
    final salesJson = prefs.getString('local_sales');
    if (salesJson != null) {
      final List<dynamic> decoded = json.decode(salesJson);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Update a sale
  static Future<void> updateSale(String id, Map<String, dynamic> updates) async {
    final sales = getSales();
    final index = sales.indexWhere((s) => s['id'] == id);
    if (index != -1) {
      sales[index] = {
        ...sales[index],
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await prefs.setString('local_sales', json.encode(sales));
    }
  }

  /// Delete a sale
  static Future<void> deleteSale(String id) async {
    final sales = getSales();
    sales.removeWhere((s) => s['id'] == id);
    await prefs.setString('local_sales', json.encode(sales));
  }

  // ===== SUPPLIERS DATA =====
  
  /// Save a supplier locally
  static Future<void> saveSupplier(Map<String, dynamic> supplier) async {
    final suppliers = getSuppliers();
    suppliers.add({
      ...supplier,
      'id': supplier['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'created_at': supplier['created_at'] ?? DateTime.now().toIso8601String(),
    });
    await prefs.setString('local_suppliers', json.encode(suppliers));
  }

  /// Get all suppliers
  static List<Map<String, dynamic>> getSuppliers() {
    final suppliersJson = prefs.getString('local_suppliers');
    if (suppliersJson != null) {
      final List<dynamic> decoded = json.decode(suppliersJson);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Update a supplier
  static Future<void> updateSupplier(String id, Map<String, dynamic> updates) async {
    final suppliers = getSuppliers();
    final index = suppliers.indexWhere((s) => s['id'] == id);
    if (index != -1) {
      suppliers[index] = {
        ...suppliers[index],
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await prefs.setString('local_suppliers', json.encode(suppliers));
    }
  }

  /// Delete a supplier
  static Future<void> deleteSupplier(String id) async {
    final suppliers = getSuppliers();
    suppliers.removeWhere((s) => s['id'] == id);
    await prefs.setString('local_suppliers', json.encode(suppliers));
  }

  // ===== CUSTOMERS DATA =====
  
  /// Save a customer locally
  static Future<void> saveCustomer(Map<String, dynamic> customer) async {
    final customers = getCustomers();
    customers.add({
      ...customer,
      'id': customer['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'created_at': customer['created_at'] ?? DateTime.now().toIso8601String(),
    });
    await prefs.setString('local_customers', json.encode(customers));
  }

  /// Get all customers
  static List<Map<String, dynamic>> getCustomers() {
    final customersJson = prefs.getString('local_customers');
    if (customersJson != null) {
      final List<dynamic> decoded = json.decode(customersJson);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Update a customer
  static Future<void> updateCustomer(String id, Map<String, dynamic> updates) async {
    final customers = getCustomers();
    final index = customers.indexWhere((c) => c['id'] == id);
    if (index != -1) {
      customers[index] = {
        ...customers[index],
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await prefs.setString('local_customers', json.encode(customers));
    }
  }

  /// Delete a customer
  static Future<void> deleteCustomer(String id) async {
    final customers = getCustomers();
    customers.removeWhere((c) => c['id'] == id);
    await prefs.setString('local_customers', json.encode(customers));
  }

  // ===== FEED DATA =====
  
  /// Save a post locally
  static Future<void> savePost(Map<String, dynamic> post) async {
    final posts = getPosts();
    posts.add({
      ...post,
      'id': post['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'created_at': post['created_at'] ?? DateTime.now().toIso8601String(),
    });
    await prefs.setString('local_posts', json.encode(posts));
  }

  /// Get all posts
  static List<Map<String, dynamic>> getPosts() {
    final postsJson = prefs.getString('local_posts');
    if (postsJson != null) {
      final List<dynamic> decoded = json.decode(postsJson);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Update a post
  static Future<void> updatePost(String id, Map<String, dynamic> updates) async {
    final posts = getPosts();
    final index = posts.indexWhere((p) => p['id'] == id);
    if (index != -1) {
      posts[index] = {
        ...posts[index],
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await prefs.setString('local_posts', json.encode(posts));
    }
  }

  /// Delete a post
  static Future<void> deletePost(String id) async {
    final posts = getPosts();
    posts.removeWhere((p) => p['id'] == id);
    await prefs.setString('local_posts', json.encode(posts));
  }

  // ===== PAYROLL DATA =====
  
  /// Save a payroll run locally
  static Future<void> savePayrollRun(Map<String, dynamic> payrollRun) async {
    final runs = getPayrollRuns();
    runs.add({
      ...payrollRun,
      'id': payrollRun['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'created_at': payrollRun['created_at'] ?? DateTime.now().toIso8601String(),
    });
    await prefs.setString('local_payroll_runs', json.encode(runs));
  }

  /// Get all payroll runs
  static List<Map<String, dynamic>> getPayrollRuns() {
    final runsJson = prefs.getString('local_payroll_runs');
    if (runsJson != null) {
      final List<dynamic> decoded = json.decode(runsJson);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Update a payroll run
  static Future<void> updatePayrollRun(String id, Map<String, dynamic> updates) async {
    final runs = getPayrollRuns();
    final index = runs.indexWhere((r) => r['id'] == id);
    if (index != -1) {
      runs[index] = {
        ...runs[index],
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await prefs.setString('local_payroll_runs', json.encode(runs));
    }
  }

  /// Delete a payroll run
  static Future<void> deletePayrollRun(String id) async {
    final runs = getPayrollRuns();
    runs.removeWhere((r) => r['id'] == id);
    await prefs.setString('local_payroll_runs', json.encode(runs));
  }

  /// Get payroll totals
  static Map<String, dynamic> getPayrollTotals() {
    final runs = getPayrollRuns();
    double totalAmount = 0.0;
    int totalRuns = runs.length;
    int totalSuppliers = 0;
    Set<String> supplierIds = {};

    for (final run in runs) {
      totalAmount += (run['total_amount'] as num?)?.toDouble() ?? 0.0;
      final payslips = run['payslips'] as List<dynamic>? ?? [];
      for (final payslip in payslips) {
        final supplierId = payslip['supplier_account_id'] as String?;
        if (supplierId != null) {
          supplierIds.add(supplierId);
        }
      }
    }

    totalSuppliers = supplierIds.length;

    return {
      'total_runs': totalRuns,
      'total_amount': totalAmount,
      'total_suppliers': totalSuppliers,
    };
  }

  // ===== CLEAR ALL DATA =====
  
  /// Clear all local data (for testing/reset)
  static Future<void> clearAllData() async {
    await prefs.remove('local_collections');
    await prefs.remove('local_sales');
    await prefs.remove('local_suppliers');
    await prefs.remove('local_customers');
    await prefs.remove('local_posts');
    await prefs.remove('local_payroll_runs');
  }
}

