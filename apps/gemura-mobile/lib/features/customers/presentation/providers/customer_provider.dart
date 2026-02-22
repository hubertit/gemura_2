import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemura/features/customers/domain/models/customer.dart';

class CustomerNotifier extends StateNotifier<List<Customer>> {
  CustomerNotifier() : super([]) {
    // Initialize with mock data
    _loadMockData();
  }

  void _loadMockData() {
    state = [
      Customer(
        id: 'CUSTOMER-1',
        name: 'Kigali Restaurant',
        phone: '+250788234567',
        email: 'info@kigalirestaurant.com',
        location: 'Kigali, Nyarugenge District',
        businessType: 'Restaurant',
        customerType: 'Restaurant',
        buyingPricePerLiter: 450.0,
        paymentMethod: 'Bank Transfer',
        bankAccount: '1234567890',
        idNumber: 'TIN123456789',
        notes: 'Regular customer, pays on time',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        isActive: true,
      ),
      Customer(
        id: 'CUSTOMER-2',
        name: 'Milk Shop Plus',
        phone: '+250788345678',
        email: 'contact@milkshopplus.com',
        location: 'Kigali, Gasabo District',
        businessType: 'Retail Shop',
        customerType: 'Shop',
        buyingPricePerLiter: 420.0,
        paymentMethod: 'Mobile Money',
        mobileMoneyNumber: '+250788345678',
        idNumber: 'TIN987654321',
        notes: 'High volume customer',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        isActive: true,
      ),
      Customer(
        id: 'CUSTOMER-3',
        name: 'Sarah Mukamana',
        phone: '+250788456789',
        location: 'Kigali, Kicukiro District',
        businessType: 'Individual',
        customerType: 'Individual',
        buyingPricePerLiter: 400.0,
        paymentMethod: 'Cash',
        notes: 'Small quantity, weekly pickup',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        isActive: true,
      ),
      Customer(
        id: 'CUSTOMER-4',
        name: 'Hotel Rwanda',
        phone: '+250788567890',
        email: 'procurement@hotelrwanda.com',
        location: 'Kigali, Kicukiro District',
        businessType: 'Hotel',
        customerType: 'Hotel',
        buyingPricePerLiter: 480.0,
        paymentMethod: 'Bank Transfer',
        bankAccount: '0987654321',
        idNumber: 'TIN456789123',
        notes: 'Premium customer, requires high quality',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        isActive: true,
      ),
      Customer(
        id: 'CUSTOMER-5',
        name: 'Café Culture',
        phone: '+250788678901',
        email: 'orders@cafeculture.com',
        location: 'Kigali, Nyarugenge District',
        businessType: 'Café',
        customerType: 'Café',
        buyingPricePerLiter: 430.0,
        paymentMethod: 'Mobile Money',
        mobileMoneyNumber: '+250788678901',
        idNumber: 'TIN789123456',
        notes: 'New customer, growing relationship',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        isActive: true,
      ),
    ];
  }

  void addCustomer(Customer customer) {
    state = [...state, customer];
  }

  void updateCustomer(Customer customer) {
    state = state.map((c) => c.id == customer.id ? customer : c).toList();
  }

  void deleteCustomer(String customerId) {
    state = state.where((c) => c.id != customerId).toList();
  }

  void toggleCustomerStatus(String customerId) {
    state = state.map((customer) {
      if (customer.id == customerId) {
        return customer.copyWith(isActive: !customer.isActive);
      }
      return customer;
    }).toList();
  }

  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return state;
    
    final searchQuery = query.toLowerCase();
    return state.where((customer) {
      return customer.name.toLowerCase().contains(searchQuery) ||
          customer.phone.toLowerCase().contains(searchQuery) ||
          customer.location.toLowerCase().contains(searchQuery) ||
          customer.businessType.toLowerCase().contains(searchQuery) ||
          customer.customerType.toLowerCase().contains(searchQuery) ||
          (customer.email != null && customer.email!.toLowerCase().contains(searchQuery)) ||
          (customer.idNumber != null && customer.idNumber!.toLowerCase().contains(searchQuery));
    }).toList();
  }

  Customer? getCustomerById(String customerId) {
    try {
      return state.firstWhere((customer) => customer.id == customerId);
    } catch (e) {
      return null;
    }
  }

  List<Customer> getActiveCustomers() {
    return state.where((customer) => customer.isActive).toList();
  }

  List<Customer> getCustomersByType(String customerType) {
    return state.where((customer) => customer.customerType == customerType).toList();
  }
}

final customerProvider = StateNotifierProvider<CustomerNotifier, List<Customer>>(
  (ref) => CustomerNotifier(),
); 