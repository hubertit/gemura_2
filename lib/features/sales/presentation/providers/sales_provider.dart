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
    required String customerAccountCode,
    required double quantity,
    required String status,
    required DateTime saleAt,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      await _salesService.recordSale(
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
}
