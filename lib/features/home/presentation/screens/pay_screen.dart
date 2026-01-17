import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/services/transaction_service.dart';

enum PayMethod { contact }

class PayScreen extends StatefulWidget {
  const PayScreen({super.key});

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _contactController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Get the amount from the controller
      final amount = double.tryParse(_amountController.text) ?? 0;
      final phoneNumber = _contactController.text.trim();
      
      // Simulate payment using the transaction service
      final transaction = await TransactionService().simulatePayment(
        phoneNumber: phoneNumber,
        amount: amount,
        walletId: 'WALLET-1', // Default wallet for now
        customerName: 'Payment Recipient',
      );
      
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      // Show success message with transaction details
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.successSnackBar(
          message: 'Payment successful! Reference: ${transaction.reference}',
        ),
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(message: 'Payment failed. Please try again.'),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            const SizedBox(height: AppTheme.spacing16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Phone Number', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppTheme.spacing8),
                  TextFormField(
                    controller: _contactController,
                    style: AppTheme.bodySmall,
                    decoration: const InputDecoration(
                      hintText: 'Enter phone number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone number required' : null,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  Text('Amount', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppTheme.spacing8),
                  TextFormField(
                    controller: _amountController,
                    style: AppTheme.bodySmall,
                    decoration: const InputDecoration(
                      hintText: 'Enter amount',
                      prefixIcon: Icon(Icons.monetization_on),
                      prefixText: 'RWF ',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Amount required' : null,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: AppTheme.spacing24),
                  PrimaryButton(
                    label: 'Pay',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


}

 