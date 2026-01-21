import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemura/core/services/sales_service.dart';
import 'package:gemura/shared/models/sale.dart';

final salesServiceProvider = Provider<SalesService>((ref) => SalesService());

final salesNotifierProvider = StateNotifierProvider<SalesNotifier, SalesState>((ref) {
  return SalesNotifier(ref.read(salesServiceProvider));
});

final salesProvider = FutureProvider<List<Sale>>((ref) async {
  final salesService = ref.read(salesServiceProvider);
  return await salesService.getSales();
});

final filteredSalesProvider = FutureProvider.family<List<Sale>, Map<String, dynamic>>((ref, filters) async {
  final salesService = ref.read(salesServiceProvider);
  return await salesService.getSales(filters: filters);
});

class SalesState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  SalesState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  SalesState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return SalesState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class SalesNotifier extends StateNotifier<SalesState> {
  final SalesService _salesService;

  SalesNotifier(this._salesService) : super(SalesState());

  Future<void> recordSale({
    String? customerAccountId,
    String? customerAccountCode,
    required double quantity,
    required String status,
    required DateTime saleAt,
    String? notes,
    String? paymentStatus,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      await _salesService.recordSale(
        customerAccountId: customerAccountId,
        customerAccountCode: customerAccountCode,
        quantity: quantity,
        status: status,
        saleAt: saleAt,
        notes: notes,
        paymentStatus: paymentStatus,
      );

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isSuccess: false,
      );
    }
  }

  Future<void> updateSale({
    required String saleId,
    String? customerAccountId,
    String? customerAccountCode,
    required double quantity,
    required String status,
    required DateTime saleAt,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      await _salesService.updateSale(
        saleId: saleId,
        customerAccountId: customerAccountId,
        customerAccountCode: customerAccountCode,
        quantity: quantity,
        status: status,
        saleAt: saleAt,
        notes: notes,
      );

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isSuccess: false,
      );
    }
  }

  Future<void> loadSales() async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      await _salesService.getSales();
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isSuccess: false,
      );
    }
  }

  void resetState() {
    state = SalesState();
  }

  Future<void> cancelSale({
    required String saleId,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      await _salesService.cancelSale(
        saleId: saleId,
      );

      state = state.copyWith(isLoading: false, isSuccess: true);
      
      // Reset state after a short delay to allow UI to update
      Future.delayed(const Duration(milliseconds: 500), () {
        if (state.isSuccess) {
          state = state.copyWith(isSuccess: false);
        }
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isSuccess: false,
      );
    }
  }
}
