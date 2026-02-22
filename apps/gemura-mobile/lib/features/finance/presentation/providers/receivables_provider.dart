import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/receivables_service.dart';
import '../../../../shared/models/receivable.dart';

final receivablesServiceProvider = Provider<ReceivablesService>((ref) {
  return ReceivablesService();
});

final receivablesProvider = FutureProvider.family<ReceivablesSummary, ReceivablesParams>(
  (ref, params) async {
    final service = ref.watch(receivablesServiceProvider);
    return await service.getReceivables(
      customerAccountId: params.customerAccountId,
      dateFrom: params.dateFrom,
      dateTo: params.dateTo,
      paymentStatus: params.paymentStatus,
    );
  },
);

class ReceivablesParams {
  final String? customerAccountId;
  final String? dateFrom;
  final String? dateTo;
  final String? paymentStatus;

  ReceivablesParams({
    this.customerAccountId,
    this.dateFrom,
    this.dateTo,
    this.paymentStatus,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceivablesParams &&
          runtimeType == other.runtimeType &&
          customerAccountId == other.customerAccountId &&
          dateFrom == other.dateFrom &&
          dateTo == other.dateTo &&
          paymentStatus == other.paymentStatus;

  @override
  int get hashCode =>
      customerAccountId.hashCode ^
      dateFrom.hashCode ^
      dateTo.hashCode ^
      paymentStatus.hashCode;
}
