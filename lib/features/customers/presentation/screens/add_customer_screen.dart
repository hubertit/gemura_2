import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:gemura/core/theme/app_theme.dart';
import 'package:gemura/shared/widgets/primary_button.dart';
import 'package:gemura/shared/utils/phone_validator.dart';
import 'package:gemura/shared/utils/rwandan_phone_input_formatter.dart';
import '../providers/customers_provider.dart';

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
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
    try {

      final contacts = await ContactsService.getContacts(withThumbnails: false);
      final contactsWithPhones = contacts.where((c) => (c.phones?.isNotEmpty ?? false)).toList();

      if (contactsWithPhones.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No contacts with phone numbers found'),
              backgroundColor: AppTheme.snackbarErrorColor,
            ),
          );
        }
        return;
      }

      if (mounted) {
        final selectedContact = await showModalBottomSheet<Contact>(
          context: context,
          backgroundColor: AppTheme.surfaceColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => _ContactPickerSheet(contacts: contactsWithPhones),
        );

        if (selectedContact != null && selectedContact.phones!.isNotEmpty) {
          final phone = selectedContact.phones!.first.value ?? '';
          setState(() {
            _phoneController.text = phone;
            // Also populate name if it's empty
            if (_nameController.text.trim().isEmpty) {
              _nameController.text = selectedContact.displayName ?? '';
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accessing contacts: $e'),
            backgroundColor: AppTheme.snackbarErrorColor,
          ),
        );
      }
    }
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        await ref.read(customersNotifierProvider.notifier).createCustomer(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          address: _addressController.text.trim(),
          pricePerLiter: double.parse(_priceController.text),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add customer: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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

              
              // Name
              TextFormField(
                controller: _nameController,
                style: AppTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Customer Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    borderSide: BorderSide(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing12),

              // Phone number field with contact picker
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      style: AppTheme.bodyMedium,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        PhoneInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        hintText: '788606765',
                        prefixIcon: const Icon(Icons.phone),
                        hintStyle: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                          borderSide: BorderSide(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                      ),
                      validator: PhoneValidator.validateRwandanPhone,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Container(
                    height: 56, // Match TextFormField height
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                      border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.contacts, color: AppTheme.primaryColor),
                      tooltip: 'Select from contacts',
                      onPressed: _pickContact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing12),

              // Email
              TextFormField(
                controller: _emailController,
                style: AppTheme.bodyMedium,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email (optional)',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    borderSide: BorderSide(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),

              // Address
              TextFormField(
                controller: _addressController,
                style: AppTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Address',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    borderSide: BorderSide(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing12),

              // Price per liter
              TextFormField(
                controller: _priceController,
                style: AppTheme.bodyMedium,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Price per Liter (RWF)',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    borderSide: BorderSide(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter price per liter';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Price must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing32),

              // Submit Button
              PrimaryButton(
                onPressed: _isSubmitting ? null : _saveCustomer,
                label: _isSubmitting ? 'Adding Customer...' : 'Add Customer',
                isLoading: _isSubmitting,
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

// Contact picker bottom sheet
class _ContactPickerSheet extends StatelessWidget {
  final List<Contact> contacts;

  const _ContactPickerSheet({required this.contacts});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: AppTheme.spacing12),
            decoration: BoxDecoration(
              color: AppTheme.textSecondaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Text('Select Contact', style: AppTheme.titleMedium),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: contacts.length,
              itemBuilder: (context, i) {
                final contact = contacts[i];
                final phone = contact.phones!.isNotEmpty ? contact.phones!.first.value ?? '' : '';
                return ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(contact.displayName ?? '', style: AppTheme.bodySmall),
                  subtitle: Text(phone, style: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor)),
                  onTap: () => Navigator.of(context).pop(contact),
                );
              },
            ),
          ),
          const SizedBox(height: AppTheme.actionSheetBottomSpacing),
        ],
      ),
    );
  }
} 