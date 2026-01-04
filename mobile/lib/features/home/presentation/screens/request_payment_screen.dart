import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';

enum RequestType { direct }

class RequestPaymentScreen extends StatefulWidget {
  const RequestPaymentScreen({super.key});

  @override
  State<RequestPaymentScreen> createState() => _RequestPaymentScreenState();
}

class _RequestPaymentScreenState extends State<RequestPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      AppTheme.successSnackBar(message: 'Payment request sent!'),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Payment'),
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

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Recipient Phone Number', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppTheme.spacing8),
                    TextFormField(
                      controller: _recipientController,
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
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Amount required';
                        final n = num.tryParse(v);
                        if (n == null || n <= 0) return 'Enter a valid amount';
                        return null;
                      },
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    Text('Note (optional)', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppTheme.spacing8),
                    TextFormField(
                      controller: _noteController,
                      style: AppTheme.bodySmall,
                      decoration: const InputDecoration(
                        hintText: 'Add a note (optional)',
                        prefixIcon: Icon(Icons.edit_note_outlined),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                    PrimaryButton(
                      label: 'Send Request',
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

 