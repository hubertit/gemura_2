import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/supplier.dart';
import '../../../../core/services/suppliers_service.dart';

final suppliersServiceProvider = Provider<SuppliersService>((ref) {
  return SuppliersService();
});

final suppliersProvider = FutureProvider<List<Supplier>>((ref) async {
  final suppliersService = ref.read(suppliersServiceProvider);
  return await suppliersService.getSuppliers();
});

final suppliersNotifierProvider = StateNotifierProvider<SuppliersNotifier, AsyncValue<List<Supplier>>>((ref) {
  final suppliersService = ref.read(suppliersServiceProvider);
  return SuppliersNotifier(suppliersService);
});

class SuppliersNotifier extends StateNotifier<AsyncValue<List<Supplier>>> {
  final SuppliersService _suppliersService;

  SuppliersNotifier(this._suppliersService) : super(const AsyncValue.loading()) {
    loadSuppliers();
  }

  Future<void> loadSuppliers() async {
    try {
      state = const AsyncValue.loading();
      final suppliers = await _suppliersService.getSuppliers();
      state = AsyncValue.data(suppliers);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshSuppliers() async {
    await loadSuppliers();
  }

  Future<void> createSupplier({
    required String name,
    required String phone,
    String? email,
    String? nid,
    String? address,
    required double pricePerLiter,
  }) async {
    try {
      // Create the supplier via API
      await _suppliersService.createSupplier(
        name: name,
        phone: phone,
        email: email,
        nid: nid,
        address: address,
        pricePerLiter: pricePerLiter,
      );
      
      // Refresh the suppliers list to get the updated data
      await loadSuppliers();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> getSupplierDetails(String supplierId) async {
    try {
      final supplierDetails = await _suppliersService.getSupplierDetails(supplierId);
      
      state.whenData((suppliers) {
        final updatedSuppliers = suppliers.map((supplier) {
          if (supplier.relationshipId == supplierId) {
            return supplier.copyWith(
              pricePerLiter: supplierDetails.pricePerLiter,
              averageSupplyQuantity: supplierDetails.averageSupplyQuantity,
              relationshipStatus: supplierDetails.relationshipStatus,
            );
          }
          return supplier;
        }).toList();
        state = AsyncValue.data(updatedSuppliers);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
