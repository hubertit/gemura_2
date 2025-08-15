import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/phone_input_field.dart';
import '../providers/suppliers_provider.dart';

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
  final _addressController = TextEditingController();
  final _nidController = TextEditingController();
  final _pricePerLiterController = TextEditingController();
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _nidController.dispose();
    _pricePerLiterController.dispose();
    super.dispose();
  }

  void _saveSupplier() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        await ref.read(suppliersNotifierProvider.notifier).createSupplier(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          nid: _nidController.text.trim().isEmpty ? null : _nidController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          pricePerLiter: double.parse(_pricePerLiterController.text),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Supplier "${_nameController.text.trim()}" added successfully!'),
              backgroundColor: AppTheme.snackbarSuccessColor,
            ),
          );

          // Navigate back to suppliers list screen
          Navigator.of(context).pop();
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add supplier: ${error.toString()}'),
              backgroundColor: AppTheme.snackbarErrorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
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
              
              PhoneInputField(
                controller: _phoneController,
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
                controller: _addressController,
                style: AppTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: 'Address (optional)',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              
              TextFormField(
                controller: _nidController,
                style: AppTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: 'National ID (optional)',
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              
              TextFormField(
                controller: _pricePerLiterController,
                style: AppTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: 'Price per liter (RWF)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Price per liter is required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing24),

              // Save Button
              PrimaryButton(
                onPressed: _isSubmitting ? null : _saveSupplier,
                label: _isSubmitting ? 'Adding Supplier...' : 'Add Supplier',
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 