import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/utils/phone_validator.dart';
import '../../../../shared/utils/rwandan_phone_input_formatter.dart';
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

  Future<void> _pickContact() async {
    try {
      final status = await Permission.contacts.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contacts permission is required to select a contact'),
              backgroundColor: AppTheme.snackbarErrorColor,
            ),
          );
        }
        return;
      }

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
              
              // Phone number field with contact picker
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      style: AppTheme.bodySmall,
                                    decoration: InputDecoration(
                hintText: '250788123456',
                prefixIcon: const Icon(Icons.phone),
                hintStyle: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor),
              ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        PhoneInputFormatter(),
                      ],
                      validator: PhoneValidator.validateRwandanPhone,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Container(
                    height: 56, // Match TextFormField height
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
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