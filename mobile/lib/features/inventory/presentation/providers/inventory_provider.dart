import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/inventory_service.dart';

final inventoryServiceProvider = Provider<InventoryService>((ref) {
  return InventoryService();
});

final inventoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, InventoryFilters>(
        (ref, filters) async {
  print('📦 [PROVIDER] inventoryProvider called with filters: status=${filters.status}, lowStock=${filters.lowStock}, hashCode=${filters.hashCode}');
  
  final inventoryService = ref.read(inventoryServiceProvider);
  print('📦 [PROVIDER] Calling getInventory API...');
  
  final result = await inventoryService.getInventory(
    status: filters.status,
    lowStock: filters.lowStock,
  );
  
  print('📦 [PROVIDER] getInventory returned ${result.length} items');
  print('📦 [PROVIDER] Items: ${result.map((e) => e['id']).toList()}');
  
  return result;
});

final inventoryStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final inventoryService = ref.read(inventoryServiceProvider);
  return await inventoryService.getInventoryStats();
});

final inventoryItemProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final inventoryService = ref.read(inventoryServiceProvider);
  return await inventoryService.getInventoryItem(id);
});

class InventoryFilters {
  final String? status;
  final bool? lowStock;

  InventoryFilters({
    this.status,
    this.lowStock,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryFilters &&
        other.status == status &&
        other.lowStock == lowStock;
  }

  @override
  int get hashCode => Object.hash(status, lowStock);
}
