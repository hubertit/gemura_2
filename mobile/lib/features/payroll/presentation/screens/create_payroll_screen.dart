import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/local_data_service.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../suppliers/presentation/screens/add_supplier_screen.dart';
import '../../../suppliers/presentation/providers/suppliers_provider.dart';
import '../../domain/models/payroll_run.dart';

class CreatePayrollScreen extends ConsumerStatefulWidget {
  const CreatePayrollScreen({super.key});

  @override
  ConsumerState<CreatePayrollScreen> createState() => _CreatePayrollScreenState();
}

class _CreatePayrollScreenState extends ConsumerState<CreatePayrollScreen> {
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
      // Get actual suppliers and collections from local storage
      final suppliers = LocalDataService.getSuppliers();
      final collections = LocalDataService.getCollections();
      
      if (suppliers.isEmpty) {
        if (mounted) {
          final shouldAddSupplier = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Suppliers Found'),
              content: const Text('You need to add suppliers before generating payroll. Would you like to add a supplier now?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Add Supplier'),
                ),
              ],
            ),
          );

          if (shouldAddSupplier == true) {
            // Navigate to add supplier screen
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddSupplierScreen(),
              ),
            );
            
            // Refresh suppliers after returning
            if (mounted) {
              ref.invalidate(suppliersNotifierProvider);
              // Try again after adding supplier
              await Future.delayed(const Duration(milliseconds: 500));
              _generatePayroll();
            }
          }
        }
        setState(() => _isProcessing = false);
        return;
      }

      if (collections.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar(message: 'No collections found. Please record collections first.'),
        );
        setState(() => _isProcessing = false);
        return;
      }
      
      // Filter collections within period
      final periodCollections = collections.where((c) {
        try {
          final collectionDate = c['collection_at'] != null
              ? DateTime.parse(c['collection_at'])
              : (c['created_at'] != null
                  ? DateTime.parse(c['created_at'])
                  : DateTime.now());
          return collectionDate.isAfter(_periodStart!.subtract(const Duration(days: 1))) &&
                 collectionDate.isBefore(_periodEnd!.add(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      }).toList();

      if (periodCollections.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar(message: 'No collections found in the selected period.'),
        );
        setState(() => _isProcessing = false);
        return;
      }

      // Group by supplier account code and calculate payments
      final Map<String, List<Map<String, dynamic>>> supplierCollections = {};
      for (final collection in periodCollections) {
        // Try multiple possible field names for supplier identifier
        final supplierCode = collection['supplier_account_code'] ?? 
                             collection['supplierAccountCode'] ??
                             collection['supplier_code'] ??
                             collection['supplier_account_id'] ??
                             collection['supplier_id'];
        
        if (supplierCode != null) {
          final code = supplierCode.toString();
          supplierCollections.putIfAbsent(code, () => []).add(collection);
        }
      }

      if (supplierCollections.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar(message: 'No supplier information found in collections.'),
        );
        setState(() => _isProcessing = false);
        return;
      }

      // Generate payslips
      final List<Map<String, dynamic>> payslips = [];
      double totalAmount = 0.0;

      for (final entry in supplierCollections.entries) {
        final supplierCode = entry.key;
        final supplierCollections = entry.value;
        
        // Find supplier by account code or id
        Map<String, dynamic>? supplier;
        try {
          supplier = suppliers.firstWhere(
            (s) {
              final sCode = s['account_code'] ?? s['accountCode'] ?? s['code'] ?? s['id'] ?? '';
              final sId = s['id'] ?? '';
              return sCode.toString() == supplierCode || sId.toString() == supplierCode;
            },
            orElse: () => <String, dynamic>{},
          );
        } catch (e) {
          supplier = null;
        }

        if (supplier == null || supplier.isEmpty) {
          // Try to find by any matching field
          supplier = suppliers.firstWhere(
            (s) => (s['account_code'] ?? s['accountCode'] ?? s['code'] ?? s['id'] ?? '').toString().contains(supplierCode) ||
                   (s['name'] ?? '').toString().contains(supplierCode),
            orElse: () => <String, dynamic>{},
          );
        }

        // Get supplier details with fallbacks
        final supplierName = supplier?['name'] ?? 
                            supplier?['account_name'] ??
                            supplier?['accountName'] ??
                            'Supplier $supplierCode';
        final supplierDisplayCode = supplier?['code'] ?? 
                                   supplier?['account_code'] ??
                                   supplier?['accountCode'] ??
                                   supplierCode;
        
        // Get price per liter from supplier or use default
        final pricePerLiter = (supplier?['price_per_liter'] as num?)?.toDouble() ??
                             (supplier?['pricePerLiter'] as num?)?.toDouble() ??
                             (supplier?['selling_price_per_liter'] as num?)?.toDouble() ??
                             (supplier?['sellingPricePerLiter'] as num?)?.toDouble() ??
                             500.0; // Default price

        // Calculate gross amount (sum of quantities * price per liter)
        // Use price from collection if available, otherwise use supplier price
        double grossAmount = 0.0;
        int collectionCount = 0;
        for (final collection in supplierCollections) {
          final quantity = (collection['quantity'] as num?)?.toDouble() ?? 0.0;
          if (quantity > 0) {
            // Use price from collection if available, otherwise use supplier price
            final collectionPrice = (collection['price_per_liter'] as num?)?.toDouble() ??
                                   (collection['unit_price'] as num?)?.toDouble() ??
                                   pricePerLiter;
            grossAmount += quantity * collectionPrice;
            collectionCount++;
          }
        }

        if (grossAmount == 0) {
          continue; // Skip suppliers with no valid collections
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
          'id': '${DateTime.now().millisecondsSinceEpoch}_$supplierCode',
          'supplier_account_id': supplierCode,
          'supplier_name': supplierName,
          'supplier_code': supplierDisplayCode,
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
              // Generate Button or Add Supplier
              Consumer(
                builder: (context, ref, child) {
                  final suppliersAsync = ref.watch(suppliersNotifierProvider);
                  return suppliersAsync.when(
                    data: (suppliers) {
                      if (suppliers.isEmpty) {
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacing16),
                              decoration: BoxDecoration(
                                color: AppTheme.warningColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                                border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppTheme.warningColor,
                                    size: 32,
                                  ),
                                  const SizedBox(height: AppTheme.spacing8),
                                  Text(
                                    'No suppliers found',
                                    style: AppTheme.titleSmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spacing4),
                                  Text(
                                    'Add suppliers to generate payroll',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing16),
                            PrimaryButton(
                              label: 'Add Supplier',
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const AddSupplierScreen(),
                                  ),
                                );
                                // Refresh suppliers after returning
                                if (mounted) {
                                  ref.invalidate(suppliersNotifierProvider);
                                }
                              },
                            ),
                          ],
                        );
                      }
                      return PrimaryButton(
                        label: _isProcessing ? 'Generating...' : 'Generate Payroll',
                        onPressed: _isProcessing ? null : _generatePayroll,
                        isLoading: _isProcessing,
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Column(
                      children: [
                        Text('Error loading suppliers: $error'),
                        const SizedBox(height: AppTheme.spacing16),
                        PrimaryButton(
                          label: 'Add Supplier',
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AddSupplierScreen(),
                              ),
                            );
                            // Refresh suppliers after returning
                            if (mounted) {
                              ref.invalidate(suppliersNotifierProvider);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

