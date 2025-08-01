import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/models/supplier.dart';
import '../providers/supplier_provider.dart';

class AddSupplierScreen extends ConsumerStatefulWidget {
  const AddSupplierScreen({super.key});

  @override
  ConsumerState<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends ConsumerState<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _cattleCountController = TextEditingController();
  final _dailyProductionController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _mobileMoneyController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedBusinessType = 'Individual Farmer';
  String _selectedFarmType = 'Small-scale';
  String _selectedCollectionSchedule = 'Morning (6 AM - 10 AM)';

  String _selectedPaymentMethod = 'Cash';

  final List<String> _businessTypes = [
    'Individual Farmer',
    'Cooperative',
    'Dairy Farm',
    'Large-scale Farm',
  ];

  final List<String> _farmTypes = [
    'Small-scale',
    'Medium-scale',
    'Large-scale',
  ];

  final List<String> _collectionSchedules = [
    'Morning (6 AM - 10 AM)',
    'Evening (4 PM - 8 PM)',
    'Both (Morning & Evening)',
  ];



  final List<String> _paymentMethods = [
    'Cash',
    'Mobile Money',
    'Bank Transfer',
    'Credit',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _cattleCountController.dispose();
    _dailyProductionController.dispose();
    _sellingPriceController.dispose();
    _bankAccountController.dispose();
    _mobileMoneyController.dispose();
    _idNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveSupplier() {
    if (_formKey.currentState!.validate()) {
      final supplier = Supplier(
        id: 'SUPPLIER-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        location: _locationController.text.trim(),
        businessType: _selectedBusinessType,
        cattleCount: int.parse(_cattleCountController.text),
        dailyProduction: double.parse(_dailyProductionController.text),
        farmType: _selectedFarmType,
        collectionSchedule: _selectedCollectionSchedule,
        sellingPricePerLiter: double.parse(_sellingPriceController.text),
        qualityGrades: 'Grade A', // Default quality grade
        paymentMethod: _selectedPaymentMethod,
        bankAccount: _bankAccountController.text.trim().isEmpty ? null : _bankAccountController.text.trim(),
        mobileMoneyNumber: _mobileMoneyController.text.trim().isEmpty ? null : _mobileMoneyController.text.trim(),
        idNumber: _idNumberController.text.trim().isEmpty ? null : _idNumberController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(supplierProvider.notifier).addSupplier(supplier);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Supplier "${supplier.name}" added successfully!'),
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
        title: const Text('Add Supplier'),
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
              Text(
                'Basic Information',
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              
              TextFormField(
                controller: _nameController,
                style: AppTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: 'Full name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing12),
              
              TextFormField(
                controller: _phoneController,
                style: AppTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: 'Phone number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing12),
              
              TextFormField(
                controller: _emailController,
                style: AppTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: 'Email (optional)',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppTheme.spacing12),
              
              TextFormField(
                controller: _locationController,
                style: AppTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: 'Location/address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Location is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Business Information
              Text(
                'Business Information',
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              
              // Business Type Selection
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedBusinessType,
                  decoration: const InputDecoration(
                    hintText: 'Select business type',
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
              
              TextFormField(
                controller: _cattleCountController,
                style: AppTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: 'Number of cattle',
                  prefixIcon: Icon(Icons.pets),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Cattle count is required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing12),
              
              TextFormField(
                controller: _dailyProductionController,
                style: AppTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: 'Daily production (liters)',
                  prefixIcon: Icon(Icons.local_drink),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Daily production is required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing12),
              
              // Farm Type Selection
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedFarmType,
                  decoration: const InputDecoration(
                    hintText: 'Select farm type',
                    prefixIcon: Icon(Icons.agriculture),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _farmTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type, style: AppTheme.bodySmall),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedFarmType = value!),
                  style: AppTheme.bodySmall,
                  dropdownColor: AppTheme.surfaceColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              
              // Collection Schedule Selection
                          Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedCollectionSchedule,
                decoration: const InputDecoration(
                  hintText: 'When do you prefer milk collection?',
                  prefixIcon: Icon(Icons.schedule),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                  items: _collectionSchedules.map((schedule) {
                    return DropdownMenuItem<String>(
                      value: schedule,
                      child: Text(schedule, style: AppTheme.bodySmall),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCollectionSchedule = value!),
                  style: AppTheme.bodySmall,
                  dropdownColor: AppTheme.surfaceColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Pricing Information
              Text(
                'Pricing Information',
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              
              TextFormField(
                controller: _sellingPriceController,
                style: AppTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: 'Selling price per liter (RWF)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Selling price is required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Payment Information
              Text(
                'Payment Information',
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              
              // Payment Method Selection
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedPaymentMethod,
                  decoration: const InputDecoration(
                    hintText: 'Select payment method',
                    prefixIcon: Icon(Icons.payment),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _paymentMethods.map((method) {
                    return DropdownMenuItem<String>(
                      value: method,
                      child: Row(
                        children: [
                          Icon(_getPaymentIcon(method), color: AppTheme.primaryColor, size: 16),
                          const SizedBox(width: 8),
                          Text(method, style: AppTheme.bodySmall),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                  style: AppTheme.bodySmall,
                  dropdownColor: AppTheme.surfaceColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              
              if (_selectedPaymentMethod == 'Bank Transfer')
                TextFormField(
                  controller: _bankAccountController,
                  style: AppTheme.bodySmall,
                  decoration: const InputDecoration(
                    hintText: 'Bank account number',
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                ),
              if (_selectedPaymentMethod == 'Mobile Money')
                TextFormField(
                  controller: _mobileMoneyController,
                  style: AppTheme.bodySmall,
                  decoration: const InputDecoration(
                    hintText: 'Mobile money number',
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              const SizedBox(height: AppTheme.spacing16),

              // Additional Information
              Text(
                'Additional Information',
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              
              TextFormField(
                controller: _idNumberController,
                style: AppTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: 'National ID or TIN (optional)',
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              
              TextFormField(
                controller: _notesController,
                style: AppTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppTheme.spacing24),
              
              // Save Button
              PrimaryButton(
                label: 'Save Supplier',
                onPressed: _saveSupplier,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPaymentIcon(String paymentMethod) {
    switch (paymentMethod) {
      case 'Cash':
        return Icons.money;
      case 'Mobile Money':
        return Icons.phone_android;
      case 'Bank Transfer':
        return Icons.account_balance;
      case 'Credit':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }
} 