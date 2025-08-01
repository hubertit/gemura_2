import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/models/loan.dart';
import '../providers/loans_provider.dart';

class CreateLoanScreen extends ConsumerStatefulWidget {
  const CreateLoanScreen({super.key});

  @override
  ConsumerState<CreateLoanScreen> createState() => _CreateLoanScreenState();
}

class _CreateLoanScreenState extends ConsumerState<CreateLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _guarantorsController = TextEditingController();

  LoanType _selectedLoanType = LoanType.cash;
  int _selectedTermInMonths = 12;
  double _interestRate = 12.0;
  DateTime? _selectedStartDate;
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _selectedStartDate = DateTime.now();
    _selectedDueDate = DateTime.now().add(Duration(days: _selectedTermInMonths * 30));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _purposeController.dispose();
    _guarantorsController.dispose();
    super.dispose();
  }

  void _onLoanTypeChanged(LoanType? type) {
    if (type != null) {
      setState(() {
        _selectedLoanType = type;
        _updateInterestRate();
      });
    }
  }

  void _onTermChanged(int? term) {
    if (term != null) {
      setState(() {
        _selectedTermInMonths = term;
        _selectedDueDate = _selectedStartDate?.add(Duration(days: term * 30));
        _updateInterestRate();
      });
    }
  }

  void _updateInterestRate() {
    switch (_selectedLoanType) {
      case LoanType.cash:
        _interestRate = _selectedTermInMonths <= 12 ? 15.0 : 12.5;
        break;
      case LoanType.device:
        _interestRate = _selectedTermInMonths <= 18 ? 12.0 : 10.0;
        break;
      case LoanType.float:
        _interestRate = _selectedTermInMonths <= 6 ? 18.0 : 15.0;
        break;
      case LoanType.product:
        _interestRate = _selectedTermInMonths <= 24 ? 12.0 : 9.0;
        break;
    }
  }

  String _getLoanTypeDisplayName(LoanType type) {
    switch (type) {
      case LoanType.cash:
        return 'Cash Loan';
      case LoanType.device:
        return 'Device/Equipment Loan';
      case LoanType.float:
        return 'Float Loan';
      case LoanType.product:
        return 'Product Loan';
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedStartDate = picked;
        _selectedDueDate = picked.add(Duration(days: _selectedTermInMonths * 30));
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
      final guarantors = _guarantorsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final loan = Loan(
        id: 'LOAN-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text,
        description: _descriptionController.text,
        type: _selectedLoanType,
        amount: amount,
        interestRate: _interestRate,
        termInMonths: _selectedTermInMonths,
        startDate: _selectedStartDate!,
        dueDate: _selectedDueDate!,
        status: LoanStatus.pending,
        walletId: 'WALLET-1', // Default wallet
        guarantors: guarantors,
        purpose: _purposeController.text.isNotEmpty ? _purposeController.text : null,
        createdAt: DateTime.now(),
      );

      ref.read(loansProvider.notifier).addLoan(loan);

      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.successSnackBar(
          message: 'Loan application submitted successfully!',
        ),
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Apply for Loan'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(
          color: AppTheme.textPrimaryColor,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          children: [
            // Loan Type Selection
            Text(
              'Loan Type',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            DropdownButtonFormField<LoanType>(
              value: _selectedLoanType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing12,
                ),
              ),
              items: LoanType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getLoanTypeDisplayName(type)),
                );
              }).toList(),
              onChanged: _onLoanTypeChanged,
            ),
            
            const SizedBox(height: AppTheme.spacing16),
            
            // Loan Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Loan Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(AppTheme.borderRadius8)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing12,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a loan name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: AppTheme.spacing16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(AppTheme.borderRadius8)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing12,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            
            const SizedBox(height: AppTheme.spacing16),
            
            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (RWF)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(AppTheme.borderRadius8)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing12,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value.replaceAll(',', ''));
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            
            const SizedBox(height: AppTheme.spacing16),
            
            // Term in Months
            Text(
              'Loan Term',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            DropdownButtonFormField<int>(
              value: _selectedTermInMonths,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing12,
                ),
              ),
              items: [6, 12, 18, 24, 36].map((term) {
                return DropdownMenuItem(
                  value: term,
                  child: Text('$term months'),
                );
              }).toList(),
              onChanged: _onTermChanged,
            ),
            
            const SizedBox(height: AppTheme.spacing16),
            
            // Interest Rate Display
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.percent,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Text(
                    'Interest Rate: ${_interestRate.toStringAsFixed(1)}%',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacing16),
            
            // Start Date
            Text(
              'Start Date',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            InkWell(
              onTap: _selectStartDate,
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.textHintColor),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: AppTheme.textSecondaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Text(
                      _selectedStartDate != null
                          ? DateFormat('MMM dd, yyyy').format(_selectedStartDate!)
                          : 'Select start date',
                      style: AppTheme.bodyMedium.copyWith(
                        color: _selectedStartDate != null
                            ? AppTheme.textPrimaryColor
                            : AppTheme.textHintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacing16),
            
            // Due Date Display
            if (_selectedDueDate != null) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  border: Border.all(
                    color: AppTheme.successColor.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event,
                      color: AppTheme.successColor,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Text(
                      'Due Date: ${DateFormat('MMM dd, yyyy').format(_selectedDueDate!)}',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
            ],
            
            // Purpose
            TextFormField(
              controller: _purposeController,
              decoration: const InputDecoration(
                labelText: 'Purpose (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(AppTheme.borderRadius8)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing12,
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacing16),
            
            // Guarantors
            TextFormField(
              controller: _guarantorsController,
              decoration: const InputDecoration(
                labelText: 'Guarantors (comma separated)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(AppTheme.borderRadius8)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing12,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter at least one guarantor';
                }
                return null;
              },
            ),
            
            const SizedBox(height: AppTheme.spacing32),
            
            // Submit Button
            PrimaryButton(
              onPressed: _submit,
              label: 'Submit Application',
            ),
            
            const SizedBox(height: AppTheme.spacing16),
          ],
        ),
      ),
    );
  }
} 