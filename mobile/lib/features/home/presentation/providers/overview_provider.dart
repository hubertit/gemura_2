import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/overview.dart';
import '../../../../core/services/overview_service.dart';

final overviewServiceProvider = Provider<OverviewService>((ref) {
  return OverviewService();
});

final overviewProvider = FutureProvider<Overview>((ref) async {
  final overviewService = ref.read(overviewServiceProvider);
  
  // Get all-time data (no date filter)
  // Backend returns all data by default when no date filters are provided
  
  return await overviewService.getOverview(
    dateFrom: null,
    dateTo: null,
  );
});

final filteredOverviewProvider = FutureProvider.family<Overview, Map<String, String>>((ref, dateRange) async {
  final overviewService = ref.read(overviewServiceProvider);
  return await overviewService.getOverview(
    dateFrom: dateRange['dateFrom'],
    dateTo: dateRange['dateTo'],
  );
});

final overviewNotifierProvider = StateNotifierProvider<OverviewNotifier, AsyncValue<Overview>>((ref) {
  final overviewService = ref.read(overviewServiceProvider);
  return OverviewNotifier(overviewService);
});

class OverviewNotifier extends StateNotifier<AsyncValue<Overview>> {
  final OverviewService _overviewService;

  OverviewNotifier(this._overviewService) : super(const AsyncValue.loading()) {
    loadOverview();
  }

  Future<void> loadOverview() async {
    try {
      state = const AsyncValue.loading();
      
      // Get all-time data (no date filter)
      // Backend returns all data by default when no date filters are provided
      
      final overview = await _overviewService.getOverview(
        dateFrom: null,
        dateTo: null,
      );
      state = AsyncValue.data(overview);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadOverviewWithDateRange({
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      state = const AsyncValue.loading();
      final overview = await _overviewService.getOverview(
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      state = AsyncValue.data(overview);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshOverview() async {
    await loadOverview();
  }
}
