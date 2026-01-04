import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/overview.dart';
import '../../../../core/services/overview_service.dart';

final overviewServiceProvider = Provider<OverviewService>((ref) {
  return OverviewService();
});

final overviewProvider = FutureProvider<Overview>((ref) async {
  final overviewService = ref.read(overviewServiceProvider);
  
  // Get data for last 90 days to include recent transactions
  final DateTime now = DateTime.now();
  final DateTime dateFrom = now.subtract(const Duration(days: 90));
  final String dateFromStr = '${dateFrom.year}-${dateFrom.month.toString().padLeft(2, '0')}-${dateFrom.day.toString().padLeft(2, '0')}';
  final String dateToStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  
  return await overviewService.getOverview(
    dateFrom: dateFromStr,
    dateTo: dateToStr,
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
      
      // Get data for last 90 days to include recent transactions
      final DateTime now = DateTime.now();
      final DateTime dateFrom = now.subtract(const Duration(days: 90));
      final String dateFromStr = '${dateFrom.year}-${dateFrom.month.toString().padLeft(2, '0')}-${dateFrom.day.toString().padLeft(2, '0')}';
      final String dateToStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final overview = await _overviewService.getOverview(
        dateFrom: dateFromStr,
        dateTo: dateToStr,
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
