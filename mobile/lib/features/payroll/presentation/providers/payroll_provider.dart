import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/payroll_service.dart';

final payrollServiceProvider = Provider<PayrollService>((ref) {
  return PayrollService();
});

final generatePayrollProvider = FutureProvider.family<Map<String, dynamic>, GeneratePayrollParams>((ref, params) async {
  final payrollService = ref.read(payrollServiceProvider);
  return await payrollService.generatePayroll(
    supplierAccountCodes: params.supplierAccountCodes,
    periodStart: params.periodStart,
    periodEnd: params.periodEnd,
    paymentTermsDays: params.paymentTermsDays,
    runName: params.runName,
  );
});

class GeneratePayrollParams {
  final List<String> supplierAccountCodes;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int? paymentTermsDays;
  final String? runName;

  GeneratePayrollParams({
    required this.supplierAccountCodes,
    required this.periodStart,
    required this.periodEnd,
    this.paymentTermsDays,
    this.runName,
  });
}

final payrollRunsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final payrollService = ref.read(payrollServiceProvider);
  return await payrollService.getPayrollRuns();
});

final markPayrollPaidProvider = FutureProvider.family<Map<String, dynamic>, MarkPayrollPaidParams>((ref, params) async {
  final payrollService = ref.read(payrollServiceProvider);
  return await payrollService.markPayrollAsPaid(
    runId: params.runId,
    paymentDate: params.paymentDate,
    payslipId: params.payslipId,
  );
});

class MarkPayrollPaidParams {
  final String runId;
  final DateTime? paymentDate;
  final String? payslipId;

  MarkPayrollPaidParams({
    required this.runId,
    this.paymentDate,
    this.payslipId,
  });
}
