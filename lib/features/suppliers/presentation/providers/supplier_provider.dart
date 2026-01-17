import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/supplier.dart';

class SupplierNotifier extends StateNotifier<List<Supplier>> {
  SupplierNotifier() : super([]) {
    _loadMockData();
  }

  void _loadMockData() {
    // Add some mock suppliers for testing
    state = [
      Supplier(
        id: 'SUPPLIER-1',
        name: 'John Kamara',
        phone: '+250788123456',
        email: 'john.kamara@email.com',
        location: 'Kigali, Gasabo District',
        businessType: 'Individual Farmer',
        cattleCount: 15,
        dailyProduction: 45.5,
        farmType: 'Small-scale',
        collectionSchedule: 'Morning',
        sellingPricePerLiter: 350.0,
        qualityGrades: 'Grade A',
        paymentMethod: 'Mobile Money',
        mobileMoneyNumber: '+250788123456',
        idNumber: '1234567890123456',
        notes: 'Reliable supplier with good quality milk',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        isActive: true,
      ),
      Supplier(
        id: 'SUPPLIER-2',
        name: 'Mukamira Cooperative',
        phone: '+250789234567',
        email: 'info@mukamira.co.rw',
        location: 'Northern Province, Musanze',
        businessType: 'Cooperative',
        cattleCount: 120,
        dailyProduction: 350.0,
        farmType: 'Large-scale',
        collectionSchedule: 'Both',
        sellingPricePerLiter: 380.0,
        qualityGrades: 'Grade A, Grade B',
        paymentMethod: 'Bank Transfer',
        bankAccount: '1234567890',
        idNumber: 'COOP-2024-001',
        notes: 'Large cooperative with consistent supply',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        isActive: true,
      ),
      Supplier(
        id: 'SUPPLIER-3',
        name: 'Marie Uwimana',
        phone: '+250790345678',
        location: 'Eastern Province, Rwamagana',
        businessType: 'Individual Farmer',
        cattleCount: 8,
        dailyProduction: 25.0,
        farmType: 'Small-scale',
        collectionSchedule: 'Evening',
        sellingPricePerLiter: 320.0,
        qualityGrades: 'Grade A',
        paymentMethod: 'Cash',
        idNumber: '9876543210987654',
        notes: 'New supplier, good quality',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        isActive: true,
      ),
    ];
  }

  void addSupplier(Supplier supplier) {
    state = [...state, supplier];
  }

  void updateSupplier(Supplier supplier) {
    state = state.map((s) => s.id == supplier.id ? supplier : s).toList();
  }

  void deleteSupplier(String supplierId) {
    state = state.where((s) => s.id != supplierId).toList();
  }

  void toggleSupplierStatus(String supplierId) {
    state = state.map((s) {
      if (s.id == supplierId) {
        return s.copyWith(isActive: !s.isActive);
      }
      return s;
    }).toList();
  }

  List<Supplier> getActiveSuppliers() {
    return state.where((s) => s.isActive).toList();
  }

  List<Supplier> searchSuppliers(String query) {
    return state.where((s) {
      return s.name.toLowerCase().contains(query.toLowerCase()) ||
             s.phone.contains(query) ||
             s.location.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}

final supplierProvider = StateNotifierProvider<SupplierNotifier, List<Supplier>>(
  (ref) => SupplierNotifier(),
); 