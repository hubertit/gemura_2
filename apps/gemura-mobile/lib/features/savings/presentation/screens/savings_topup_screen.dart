import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/models/savings_goal.dart';
import '../providers/savings_provider.dart';

class SavingsTopupSheet extends ConsumerStatefulWidget {
  final SavingsGoal? goal;

  const SavingsTopupSheet({
    super.key,
    this.goal,
  });

  @override
  ConsumerState<SavingsTopupSheet> createState() => _SavingsTopupSheetState();
}

class _SavingsTopupSheetState extends ConsumerState<SavingsTopupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String? _selectedMethod = 'Mobile Money';
  final List<String> _methods = ['Mobile Money', 'Card', 'Bank'];
  SavingsGoal? _selectedGoal;

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.goal;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final amount = double.parse(_amountController.text);
      ref.read(savingsProvider.notifier).addContribution(_selectedGoal!.id, amount);
      
      if (!mounted) return;
      
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.successSnackBar(
          message: 'Added ${NumberFormat.currency(symbol: _selectedGoal!.currency).format(amount)} to ${_selectedGoal!.name}',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(
          message: 'Failed to add contribution. Please try again.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacing16, 
        right: AppTheme.spacing16, 
        bottom: bottom + AppTheme.spacing16, 
        top: AppTheme.spacing16
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add Money to ${_selectedGoal?.name ?? 'Savings'}', 
              style: AppTheme.titleMedium, 
              textAlign: TextAlign.center
            ),
            const SizedBox(height: AppTheme.spacing16),
            
            // Amount
            Text(
              'Amount',
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            TextFormField(
              controller: _amountController,
              style: AppTheme.bodySmall,
              decoration: const InputDecoration(
                hintText: 'Enter amount',
                                        prefixIcon: Icon(Icons.monetization_on),
                        prefixText: 'RWF ',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Amount required';
                final n = num.tryParse(v);
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            
            const SizedBox(height: AppTheme.spacing16),
            
            // Payment Method
            Text(
              'Payment Method',
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            DropdownButtonFormField<String>(
              value: _selectedMethod,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.payment),
                border: OutlineInputBorder(),
              ),
              items: _methods.map((m) => DropdownMenuItem(
                value: m,
                child: Text(m),
              )).toList(),
              onChanged: (m) => setState(() => _selectedMethod = m),
              validator: (m) => m == null ? 'Select a method' : null,
            ),
            
            const SizedBox(height: AppTheme.spacing16),
            
            // Submit Button
            PrimaryButton(
              label: 'Submit',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _submit,
            ),
            
            const SizedBox(height: AppTheme.actionSheetBottomSpacing),
          ],
        ),
      ),
    );
  }
}