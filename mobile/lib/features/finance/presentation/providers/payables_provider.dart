import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/payables_service.dart';
import '../../../../shared/models/payable.dart';

final payablesServiceProvider = Provider<PayablesService>((ref) {
  return PayablesService();
});

final payablesProvider = FutureProvider.family<PayablesSummary, PayablesParams>(
  (ref, params) async {
    final service = ref.watch(payablesServiceProvider);
    return await service.getPayables(
      supplierAccountId: params.supplierAccountId,
      dateFrom: params.dateFrom,
      dateTo: params.dateTo,
      paymentStatus: params.paymentStatus,
    );
  },
);

class PayablesParams {
  final String? supplierAccountId;
  final String? dateFrom;
  final String? dateTo;
  final String? paymentStatus;

  PayablesParams({
    this.supplierAccountId,
    this.dateFrom,
    this.dateTo,
    this.paymentStatus,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayablesParams &&
          runtimeType == other.runtimeType &&
          supplierAccountId == other.supplierAccountId &&
          dateFrom == other.dateFrom &&
          dateTo == other.dateTo &&
          paymentStatus == other.paymentStatus;

  @override
  int get hashCode =>
      supplierAccountId.hashCode ^
      dateFrom.hashCode ^
      dateTo.hashCode ^
      paymentStatus.hashCode;
}
