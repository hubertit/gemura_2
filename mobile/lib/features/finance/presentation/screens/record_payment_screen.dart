import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/receivables_provider.dart';
import '../providers/payables_provider.dart';

class RecordPaymentScreen extends ConsumerStatefulWidget {
  final String type; // 'receivable' or 'payable'
  final String saleId; // For receivable
  final String collectionId; // For payable
  final String customerName; // For receivable
  final String supplierName; // For payable
  final double outstanding;
  final VoidCallback onSuccess;

  const RecordPaymentScreen({
    super.key,
    required this.type,
    this.saleId = '',
    this.collectionId = '',
    this.customerName = '',
    this.supplierName = '',
    required this.outstanding,
    required this.onSuccess,
  });

  @override
  ConsumerState<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.outstanding.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(2020);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.parse(_amountController.text);

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Payment amount must be greater than 0'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (amount > widget.outstanding) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment amount cannot exceed outstanding balance of ${_formatAmount(widget.outstanding)} RWF'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (widget.type == 'receivable') {
        final service = ref.read(receivablesServiceProvider);
        await service.recordPayment(
          saleId: widget.saleId,
          amount: amount,
          paymentDate: _selectedDate.toIso8601String().split('T')[0],
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      } else {
        final service = ref.read(payablesServiceProvider);
        await service.recordPayment(
          collectionId: widget.collectionId,
          amount: amount,
          paymentDate: _selectedDate.toIso8601String().split('T')[0],
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment recorded successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        
        // Check if this is a stale data error (outstanding balance mismatch)
        if (errorMessage.contains('exceeds outstanding balance') || 
            errorMessage.contains('Outstanding: 0')) {
          // Show helpful message first
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'This item has already been paid. Refreshing the list...',
              ),
              backgroundColor: AppTheme.warningColor,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Refresh the parent data and close the screen
          widget.onSuccess(); // This will refresh the receivables/payables list
          
          // Close the screen after a short delay to allow refresh
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${errorMessage.replaceAll('Exception: ', '')}'),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.type == 'receivable' ? widget.customerName : widget.supplierName;
    final title = widget.type == 'receivable' ? 'Record Payment - Receivable' : 'Record Payment - Payable';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(
          color: AppTheme.textPrimaryColor,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  border: Border.all(
                    color: AppTheme.thinBorderColor,
                    width: AppTheme.thinBorderWidth,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.type == 'receivable' ? 'Customer' : 'Supplier',
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      name,
                      style: AppTheme.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    Divider(height: 1, color: AppTheme.borderColor),
                    const SizedBox(height: AppTheme.spacing12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Outstanding Balance',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        Text(
                          '${_formatAmount(widget.outstanding)} RWF',
                          style: AppTheme.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: widget.type == 'receivable' ? AppTheme.successColor : AppTheme.warningColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),

              // Amount Field
              Text(
                'Payment Amount',
                style: AppTheme.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (RWF)',
                  hintText: 'Enter payment amount',
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    tooltip: 'Use full outstanding amount',
                    onPressed: () {
                      _amountController.text = widget.outstanding.toStringAsFixed(0);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                ),
                style: AppTheme.bodyMedium,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount > widget.outstanding) {
                    return 'Amount cannot exceed outstanding balance';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Date Field
              Text(
                'Payment Date',
                style: AppTheme.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                  ),
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                    style: AppTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Notes Field
              Text(
                'Notes (Optional)',
                style: AppTheme.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Payment notes',
                  hintText: 'e.g., Payment via mobile money',
                  prefixIcon: const Icon(Icons.note_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                ),
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacing24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Record Payment',
                        style: AppTheme.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
