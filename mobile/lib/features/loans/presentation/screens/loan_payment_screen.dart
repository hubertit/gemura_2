import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/loan.dart';
import '../../domain/models/loan_repayment.dart';
import '../providers/loans_provider.dart';


class LoanPaymentScreen extends ConsumerStatefulWidget {
  final Loan loan;

  const LoanPaymentScreen({
    super.key,
    required this.loan,
  });

  @override
  ConsumerState<LoanPaymentScreen> createState() => _LoanPaymentScreenState();
}

class _LoanPaymentScreenState extends ConsumerState<LoanPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  PaymentMethod _selectedPaymentMethod = PaymentMethod.mobileMoney;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'Mobile Money', 'method': PaymentMethod.mobileMoney},
    {'name': 'Bank Transfer', 'method': PaymentMethod.bankTransfer},
    {'name': 'Cash', 'method': PaymentMethod.cash},
    {'name': 'Card', 'method': PaymentMethod.card},
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill with minimum payment amount
    _amountController.text = (widget.loan.monthlyPayment ?? 0).toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Update loan with payment
      ref.read(loansProvider.notifier).makePayment(widget.loan.id, amount, _selectedPaymentMethod);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar(
            message: 'Payment of ${NumberFormat('#,##0', 'en_US').format(amount)} RWF processed successfully!',
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar(message: 'Payment failed. Please try again.'),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Make Payment',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Loan Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacing16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                          border: Border.all(
          color: AppTheme.thinBorderColor,
          width: AppTheme.thinBorderWidth,
        ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loan Summary',
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    _buildSummaryRow('Loan Name', widget.loan.name),
                    _buildSummaryRow('Type', widget.loan.typeDisplayName),
                    _buildSummaryRow('Remaining Balance', '${NumberFormat('#,##0', 'en_US').format(widget.loan.remainingBalance ?? widget.loan.amount)} RWF'),
                    _buildSummaryRow('Monthly Payment', '${NumberFormat('#,##0', 'en_US').format(widget.loan.monthlyPayment ?? 0)} RWF'),
                    _buildSummaryRow('Due Date', DateFormat('MMM dd, yyyy').format(widget.loan.dueDate)),
                  ],
                ),
              ),
              
              const SizedBox(height: AppTheme.spacing24),
              
              // Payment Amount
              Text(
                'Payment Amount',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textPrimaryColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  hintStyle: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                  prefixText: 'RWF ',
                  prefixStyle: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    borderSide: BorderSide(
                      color: AppTheme.thinBorderColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    borderSide: BorderSide(
                      color: AppTheme.thinBorderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    borderSide: BorderSide(
                      color: AppTheme.errorColor,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter payment amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount > (widget.loan.remainingBalance ?? widget.loan.amount)) {
                    return 'Amount cannot exceed remaining balance';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppTheme.spacing24),
              
              // Payment Method
              Text(
                'Payment Method',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                                  border: Border.all(
                  color: AppTheme.thinBorderColor,
                ),
                ),
                child: DropdownButtonFormField<PaymentMethod>(
                  value: _selectedPaymentMethod,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textPrimaryColor,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                  ),
                  dropdownColor: AppTheme.surfaceColor,
                  items: _paymentMethods.map((method) {
                    return DropdownMenuItem<PaymentMethod>(
                      value: method['method'] as PaymentMethod,
                      child: Text(
                        method['name'] as String,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value!;
                    });
                  },
                ),
              ),
              
              const SizedBox(height: AppTheme.spacing32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _submitPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.surfaceColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    ),
                  ),
                  child: _isProcessing
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.surfaceColor,
                            ),
                          ),
                        )
                      : Text(
                          'Process Payment',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.surfaceColor,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
} 