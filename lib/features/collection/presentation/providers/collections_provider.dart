import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/collection.dart';
import '../../../../core/services/collections_service.dart';

final collectionsServiceProvider = Provider<CollectionsService>((ref) {
  return CollectionsService();
});

final collectionsProvider = FutureProvider<List<Collection>>((ref) async {
  final collectionsService = ref.read(collectionsServiceProvider);
  return await collectionsService.getCollections();
});

final filteredCollectionsProvider = FutureProvider.family<List<Collection>, Map<String, dynamic>>((ref, filters) async {
  final collectionsService = ref.read(collectionsServiceProvider);
  return await collectionsService.getFilteredCollections(
    supplierAccountCode: filters['supplier_account_code'],
    status: filters['status'],
    dateFrom: filters['date_from'] != null ? DateTime.parse(filters['date_from']) : null,
    dateTo: filters['date_to'] != null ? DateTime.parse(filters['date_to']) : null,
    quantityMin: filters['quantity_min']?.toDouble(),
    quantityMax: filters['quantity_max']?.toDouble(),
    priceMin: filters['price_min']?.toDouble(),
    priceMax: filters['price_max']?.toDouble(),
    limit: filters['limit'],
    offset: filters['offset'],
  );
});

final collectionsNotifierProvider = StateNotifierProvider<CollectionsNotifier, AsyncValue<List<Collection>>>((ref) {
  final collectionsService = ref.read(collectionsServiceProvider);
  return CollectionsNotifier(collectionsService);
});

class CollectionsNotifier extends StateNotifier<AsyncValue<List<Collection>>> {
  final CollectionsService _collectionsService;

  CollectionsNotifier(this._collectionsService) : super(const AsyncValue.loading()) {
    loadCollections();
  }

  Future<void> loadCollections() async {
    try {
      state = const AsyncValue.loading();
      final collections = await _collectionsService.getCollections();
      state = AsyncValue.data(collections);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshCollections() async {
    await loadCollections();
  }

  Future<void> loadFilteredCollections({
    String? supplierAccountCode,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    double? quantityMin,
    double? quantityMax,
    double? priceMin,
    double? priceMax,
    int? limit,
    int? offset,
  }) async {
    try {
      state = const AsyncValue.loading();
      final collections = await _collectionsService.getFilteredCollections(
        supplierAccountCode: supplierAccountCode,
        status: status,
        dateFrom: dateFrom,
        dateTo: dateTo,
        quantityMin: quantityMin,
        quantityMax: quantityMax,
        priceMin: priceMin,
        priceMax: priceMax,
        limit: limit,
        offset: offset,
      );
      state = AsyncValue.data(collections);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createCollection({
    required String supplierAccountCode,
    required double quantity,
    required String status,
    String? notes,
    required DateTime collectionAt,
  }) async {
    try {
      // Create the collection via API
      await _collectionsService.createCollection(
        supplierAccountCode: supplierAccountCode,
        quantity: quantity,
        status: status,
        notes: notes,
        collectionAt: collectionAt,
      );
      
      // Add a small delay to ensure the backend has processed the creation
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Refresh the collections list to get the updated data
      await loadCollections();
    } catch (error) {
      // Don't set the entire state to error if collection creation fails
      // Just rethrow the error to be handled by the UI
      rethrow;
    }
  }

  Future<void> updateCollection({
    required String collectionId,
    double? quantity,
    double? pricePerLiter,
    String? status,
    DateTime? collectionAt,
    String? notes,
  }) async {
    try {
      // Update the collection via API
      await _collectionsService.updateCollection(
        collectionId: collectionId,
        quantity: quantity,
        pricePerLiter: pricePerLiter,
        status: status,
        collectionAt: collectionAt,
        notes: notes,
      );
      
      // Refresh the collections list to get the updated data
      await loadCollections();
    } catch (error) {
      // Don't set the entire state to error if update fails
      // Just rethrow the error to be handled by the UI
      rethrow;
    }
  }

  Future<void> cancelCollection({
    required String collectionId,
  }) async {
    try {
      // Cancel the collection via API
      await _collectionsService.cancelCollection(
        collectionId: collectionId,
      );
      
      // Refresh the collections list to get the updated data
      await loadCollections();
    } catch (error) {
      // Don't set the entire state to error if cancellation fails
      // Just rethrow the error to be handled by the UI
      rethrow;
    }
  }

  Future<void> deleteCollection({
    required String collectionId,
  }) async {
    try {
      // Delete the collection via API
      await _collectionsService.deleteCollection(
        collectionId: collectionId,
      );
      
      // Refresh the collections list to get the updated data
      await loadCollections();
    } catch (error) {
      // Don't set the entire state to error if deletion fails
      // Just rethrow the error to be handled by the UI
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCollectionStats() async {
    try {
      return await _collectionsService.getCollectionStats();
    } catch (error) {
      rethrow;
    }
  }

  // Helper methods for filtering and searching
  List<Collection> getCollectionsBySupplier(String supplierId) {
    return state.when(
      data: (collections) => collections.where((collection) => collection.supplierId == supplierId).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  List<Collection> getCollectionsByStatus(String status) {
    return state.when(
      data: (collections) => collections.where((collection) => collection.status == status).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  List<Collection> searchCollections(String query) {
    return state.when(
      data: (collections) {
        if (query.isEmpty) return collections;
        
        final searchQuery = query.toLowerCase();
        return collections.where((collection) {
          return collection.supplierName.toLowerCase().contains(searchQuery) ||
                 collection.supplierPhone.toLowerCase().contains(searchQuery) ||
                 collection.notes?.toLowerCase().contains(searchQuery) == true ||
                 collection.status.toLowerCase().contains(searchQuery);
        }).toList();
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  List<Collection> getCollectionsByDateRange(DateTime startDate, DateTime endDate) {
    return state.when(
      data: (collections) => collections.where((collection) {
        return collection.collectionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
               collection.collectionDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  // Statistics methods
  double get totalQuantity {
    return state.when(
      data: (collections) => collections.fold(0.0, (sum, collection) => sum + collection.quantity),
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );
  }

  double get totalValue {
    return state.when(
      data: (collections) => collections.fold(0.0, (sum, collection) => sum + collection.totalValue),
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );
  }

  int get totalCollections {
    return state.when(
      data: (collections) => collections.length,
      loading: () => 0,
      error: (_, __) => 0,
    );
  }

  Map<String, int> get statusCounts {
    return state.when(
      data: (collections) {
        final counts = <String, int>{};
        for (final collection in collections) {
          counts[collection.status] = (counts[collection.status] ?? 0) + 1;
        }
        return counts;
      },
      loading: () => {},
      error: (_, __) => {},
    );
  }
}

// Additional providers for filtered data
final collectionsBySupplierProvider = Provider.family<List<Collection>, String>((ref, supplierId) {
  final notifier = ref.watch(collectionsNotifierProvider.notifier);
  return notifier.getCollectionsBySupplier(supplierId);
});

final collectionsByStatusProvider = Provider.family<List<Collection>, String>((ref, status) {
  final notifier = ref.watch(collectionsNotifierProvider.notifier);
  return notifier.getCollectionsByStatus(status);
});

final searchCollectionsProvider = Provider.family<List<Collection>, String>((ref, query) {
  final notifier = ref.watch(collectionsNotifierProvider.notifier);
  return notifier.searchCollections(query);
});

final collectionsStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final notifier = ref.watch(collectionsNotifierProvider.notifier);
  return {
    'totalQuantity': notifier.totalQuantity,
    'totalValue': notifier.totalValue,
    'totalCollections': notifier.totalCollections,
    'statusCounts': notifier.statusCounts,
  };
});
