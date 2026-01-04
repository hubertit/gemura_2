import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/local_data_service.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/models/payroll_run.dart';

class CreatePayrollScreen extends StatefulWidget {
  const CreatePayrollScreen({super.key});

  @override
  State<CreatePayrollScreen> createState() => _CreatePayrollScreenState();
}

class _CreatePayrollScreenState extends State<CreatePayrollScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _periodStart;
  DateTime? _periodEnd;
  int _paymentTermsDays = 15;
  bool _isProcessing = false;

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    // Set default period to last 15 days
    _periodEnd = DateTime.now();
    _periodStart = _periodEnd!.subtract(const Duration(days: 15));
  }

  void _selectPeriodStart() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _periodStart ?? DateTime.now().subtract(const Duration(days: 15)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: _periodEnd ?? DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _periodStart = picked;
      });
    }
  }

  void _selectPeriodEnd() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _periodEnd ?? DateTime.now(),
      firstDate: _periodStart ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _periodEnd = picked;
      });
    }
  }

  Future<void> _generatePayroll() async {
    if (!_formKey.currentState!.validate()) return;
    if (_periodStart == null || _periodEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(message: 'Please select period dates'),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Simulate payroll calculation based on milk sales
      // In real app, this would fetch from API
      final suppliers = LocalDataService.getSuppliers();
      final collections = LocalDataService.getCollections();
      
      // Filter collections within period
      final periodCollections = collections.where((c) {
        final collectionDate = c['collection_at'] != null
            ? DateTime.parse(c['collection_at'])
            : DateTime.parse(c['created_at']);
        return collectionDate.isAfter(_periodStart!.subtract(const Duration(days: 1))) &&
               collectionDate.isBefore(_periodEnd!.add(const Duration(days: 1)));
      }).toList();

      // Group by supplier and calculate payments
      final Map<String, List<Map<String, dynamic>>> supplierCollections = {};
      for (final collection in periodCollections) {
        final supplierId = collection['supplier_account_id'] ?? collection['supplier_id'] ?? 'unknown';
        supplierCollections.putIfAbsent(supplierId, () => []).add(collection);
      }

      // Generate payslips
      final List<Map<String, dynamic>> payslips = [];
      double totalAmount = 0.0;

      for (final entry in supplierCollections.entries) {
        final supplierId = entry.key;
        final supplierCollections = entry.value;
        
        // Find supplier name
        final supplier = suppliers.firstWhere(
          (s) => (s['id'] ?? s['account_id'] ?? '').toString() == supplierId,
          orElse: () => {'name': 'Supplier $supplierId', 'code': supplierId},
        );

        // Calculate gross amount (sum of quantities * price per liter)
        double grossAmount = 0.0;
        for (final collection in supplierCollections) {
          final quantity = (collection['quantity'] as num?)?.toDouble() ?? 0.0;
          final pricePerLiter = (supplier['price_per_liter'] as num?)?.toDouble() ?? 500.0;
          grossAmount += quantity * pricePerLiter;
        }

        // Calculate deductions (simplified - 5% fee)
        final deductions = [
          {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'name': 'Processing Fee',
            'type': 'fee',
            'amount': grossAmount * 0.05,
            'description': '5% processing fee',
          }
        ];
        final totalDeductions = grossAmount * 0.05;
        final netAmount = grossAmount - totalDeductions;

        payslips.add({
          'id': '${DateTime.now().millisecondsSinceEpoch}_$supplierId',
          'supplier_account_id': supplierId,
          'supplier_name': supplier['name'] ?? 'Unknown Supplier',
          'supplier_code': supplier['code'] ?? supplierId,
          'gross_amount': grossAmount,
          'net_amount': netAmount,
          'total_deductions': totalDeductions,
          'milk_sales_count': supplierCollections.length,
          'period_start': _periodStart!.toIso8601String(),
          'period_end': _periodEnd!.toIso8601String(),
          'deductions': deductions,
          'created_at': DateTime.now().toIso8601String(),
        });

        totalAmount += netAmount;
      }

      // Create payroll run
      final payrollRun = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'run_date': DateTime.now().toIso8601String(),
        'period_start': _periodStart!.toIso8601String(),
        'period_end': _periodEnd!.toIso8601String(),
        'payment_terms_days': _paymentTermsDays,
        'total_amount': totalAmount,
        'status': 'processed',
        'payslips': payslips,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Save locally
      await LocalDataService.savePayrollRun(payrollRun);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar(
            message: 'Payroll generated successfully! Total: ${NumberFormat.currency(symbol: 'RWF ').format(totalAmount)}',
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar(message: 'Failed to generate payroll: $e'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Payroll'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Period Selection Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                  side: BorderSide(color: AppTheme.borderColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Period',
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                      // Period Start
                      InkWell(
                        onTap: _selectPeriodStart,
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spacing12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 20, color: AppTheme.textSecondaryColor),
                              const SizedBox(width: AppTheme.spacing8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Period Start',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _periodStart != null
                                          ? _dateFormat.format(_periodStart!)
                                          : 'Select start date',
                                      style: AppTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      // Period End
                      InkWell(
                        onTap: _selectPeriodEnd,
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spacing12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 20, color: AppTheme.textSecondaryColor),
                              const SizedBox(width: AppTheme.spacing8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Period End',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _periodEnd != null
                                          ? _dateFormat.format(_periodEnd!)
                                          : 'Select end date',
                                      style: AppTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              // Payment Terms
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                  side: BorderSide(color: AppTheme.borderColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Terms',
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Payment Terms (Days)',
                              style: AppTheme.bodyMedium,
                            ),
                          ),
                          Container(
                            width: 100,
                            child: TextFormField(
                              initialValue: _paymentTermsDays.toString(),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacing8,
                                  vertical: AppTheme.spacing12,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _paymentTermsDays = int.tryParse(value) ?? 15;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Text(
                        'Suppliers will be paid ${_paymentTermsDays} days after the period end',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),
              // Generate Button
              PrimaryButton(
                label: 'Generate Payroll',
                onPressed: _isProcessing ? null : _generatePayroll,
                isLoading: _isProcessing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

