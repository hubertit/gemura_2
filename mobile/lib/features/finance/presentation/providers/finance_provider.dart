import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/finance_service.dart';
import '../../domain/models/income_statement.dart';
import '../../domain/models/transaction.dart';

final financeServiceProvider = Provider<FinanceService>((ref) {
  return FinanceService();
});

final incomeStatementProvider = FutureProvider.family<IncomeStatement, IncomeStatementParams>(
  (ref, params) async {
    final service = ref.watch(financeServiceProvider);
    return await service.getIncomeStatement(
      fromDate: params.fromDate,
      toDate: params.toDate,
    );
  },
);

class IncomeStatementParams {
  final DateTime fromDate;
  final DateTime toDate;

  IncomeStatementParams({
    required this.fromDate,
    required this.toDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncomeStatementParams &&
          runtimeType == other.runtimeType &&
          fromDate == other.fromDate &&
          toDate == other.toDate;

  @override
  int get hashCode => fromDate.hashCode ^ toDate.hashCode;
}

final transactionsProvider = FutureProvider.family<List<Transaction>, TransactionsParams>(
  (ref, params) async {
    final service = ref.watch(financeServiceProvider);
    return await service.getTransactions(
      type: params.type,
      dateFrom: params.dateFrom,
      dateTo: params.dateTo,
      limit: params.limit,
    );
  },
);

class TransactionsParams {
  final String? type;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int? limit;

  TransactionsParams({
    this.type,
    this.dateFrom,
    this.dateTo,
    this.limit,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionsParams &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          dateFrom == other.dateFrom &&
          dateTo == other.dateTo &&
          limit == other.limit;

  @override
  int get hashCode => type.hashCode ^ dateFrom.hashCode ^ dateTo.hashCode ^ limit.hashCode;
}
