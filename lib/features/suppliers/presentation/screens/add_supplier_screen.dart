import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:contacts_service/contacts_service.dart';
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
class _ContactPickerSheet extends StatefulWidget {
  final List<Contact> contacts;

  const _ContactPickerSheet({required this.contacts});

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  String _searchQuery = '';
  List<Contact> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _filteredContacts = widget.contacts;
  }

  void _filterContacts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredContacts = widget.contacts;
      } else {
        _filteredContacts = widget.contacts.where((contact) {
          final name = (contact.displayName ?? '').toLowerCase();
          final phone = contact.phones?.map((p) => (p.value ?? '').toLowerCase()).join(' ') ?? '';
          final searchTerm = query.toLowerCase();
          return name.contains(searchTerm) || phone.contains(searchTerm);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                  Expanded(
                    child: Text(
                      'Select Contact',
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the close button
                ],
              ),
            ),
            
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  onChanged: _filterContacts,
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Contacts count
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_filteredContacts.length} contact${_filteredContacts.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            
            // Contacts list
            Expanded(
              child: _filteredContacts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty 
                                ? 'No contacts found'
                                : 'No contacts match "${_searchQuery}"',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Try a different search term',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = _filteredContacts[index];
                        final phone = contact.phones?.isNotEmpty == true 
                            ? contact.phones!.first.value ?? '' 
                            : '';
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              child: Text(
                                (contact.displayName ?? '?')[0].toUpperCase(),
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            title: Text(
                              contact.displayName ?? 'Unknown Contact',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: phone.isNotEmpty
                                ? Text(
                                    phone,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  )
                                : null,
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey[400],
                              size: 16,
                            ),
                            onTap: () => Navigator.of(context).pop(contact),
                          ),
                        );
                      },
                    ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
} 