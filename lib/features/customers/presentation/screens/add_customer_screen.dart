import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemura/core/theme/app_theme.dart';
import 'package:gemura/features/customers/domain/models/customer.dart';
import 'package:gemura/features/customers/presentation/providers/customer_provider.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _mobileMoneyController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedBusinessType = 'Individual';
  String _selectedCustomerType = 'Individual';
  String _selectedPaymentMethod = 'Cash';

  final List<String> _businessTypes = [
    'Individual',
    'Restaurant',
    'Hotel',
    'Shop',
    'Café',
    'School',
    'Hospital',
    'Other',
  ];

  final List<String> _customerTypes = [
    'Individual',
    'Restaurant',
    'Hotel',
    'Shop',
    'Café',
    'School',
    'Hospital',
    'Other',
  ];

  final List<String> _paymentMethods = [
    'Cash',
    'Mobile Money',
    'Bank Transfer',
    'Check',
    'Credit Card',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _idNumberController.dispose();
    _notesController.dispose();
    _bankAccountController.dispose();
    _mobileMoneyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final customer = Customer(
        id: 'CUSTOMER-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        location: _locationController.text.trim(),
        businessType: _selectedBusinessType,
        customerType: _selectedCustomerType,
        buyingPricePerLiter: double.parse(_priceController.text),
        paymentMethod: _selectedPaymentMethod,
        bankAccount: _bankAccountController.text.trim().isEmpty ? null : _bankAccountController.text.trim(),
        mobileMoneyNumber: _mobileMoneyController.text.trim().isEmpty ? null : _mobileMoneyController.text.trim(),
        idNumber: _idNumberController.text.trim().isEmpty ? null : _idNumberController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      ref.read(customerProvider.notifier).addCustomer(customer);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer added successfully!'),
          backgroundColor: AppTheme.snackbarSuccessColor,
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
        title: const Text('Add Customer'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Information
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: AppTheme.spacing12),
              
              // Name
              TextFormField(
                controller: _nameController,
                style: AppTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: 'Customer Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing12),

              // Phone
              TextFormField(
                controller: _phoneController,
                style: AppTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing12),

              // Email
              TextFormField(
                controller: _emailController,
                style: AppTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: 'Email (optional)',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),

              // Location
              TextFormField(
                controller: _locationController,
                style: AppTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: 'Location',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Business Information
              _buildSectionTitle('Business Information'),
              const SizedBox(height: AppTheme.spacing12),

              // Business Type
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedBusinessType,
                  decoration: const InputDecoration(
                    hintText: 'Business Type',
                    prefixIcon: Icon(Icons.business),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _businessTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type, style: AppTheme.bodySmall),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedBusinessType = value!),
                  style: AppTheme.bodySmall,
                  dropdownColor: AppTheme.surfaceColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),

              // Customer Type
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedCustomerType,
                  decoration: const InputDecoration(
                    hintText: 'Customer Type',
                    prefixIcon: Icon(Icons.category),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _customerTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type, style: AppTheme.bodySmall),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCustomerType = value!),
                  style: AppTheme.bodySmall,
                  dropdownColor: AppTheme.surfaceColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),

              // Buying Price
              TextFormField(
                controller: _priceController,
                style: AppTheme.bodySmall,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Buying Price per Liter (Frw)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter buying price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing12),

              // ID Number
              TextFormField(
                controller: _idNumberController,
                style: AppTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: 'National ID or TIN (optional)',
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Payment Information
              _buildSectionTitle('Payment Information'),
              const SizedBox(height: AppTheme.spacing12),

              // Payment Method
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedPaymentMethod,
                  decoration: const InputDecoration(
                    hintText: 'Payment Method',
                    prefixIcon: Icon(Icons.payment),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _paymentMethods.map((method) {
                    return DropdownMenuItem<String>(
                      value: method,
                      child: Text(method, style: AppTheme.bodySmall),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                  style: AppTheme.bodySmall,
                  dropdownColor: AppTheme.surfaceColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),

              // Bank Account
              if (_selectedPaymentMethod == 'Bank Transfer')
                TextFormField(
                  controller: _bankAccountController,
                  style: AppTheme.bodySmall,
                  decoration: const InputDecoration(
                    hintText: 'Bank Account Number',
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                ),
              if (_selectedPaymentMethod == 'Bank Transfer') const SizedBox(height: AppTheme.spacing12),

              // Mobile Money
              if (_selectedPaymentMethod == 'Mobile Money')
                TextFormField(
                  controller: _mobileMoneyController,
                  style: AppTheme.bodySmall,
                  decoration: const InputDecoration(
                    hintText: 'Mobile Money Number',
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                ),
              if (_selectedPaymentMethod == 'Mobile Money') const SizedBox(height: AppTheme.spacing12),

              // Notes
              _buildSectionTitle('Additional Information'),
              const SizedBox(height: AppTheme.spacing12),

              TextFormField(
                controller: _notesController,
                style: AppTheme.bodySmall,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.note),
                ),
              ),
              const SizedBox(height: AppTheme.spacing32),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  ),
                ),
                child: const Text(
                  'Add Customer',
                  style: TextStyle(
                    fontSize: 16,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.titleMedium.copyWith(
        color: AppTheme.textPrimaryColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }
} 