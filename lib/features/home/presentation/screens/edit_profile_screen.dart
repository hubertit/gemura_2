import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/phone_input_field.dart';
import '../../../../../shared/widgets/custom_app_bar.dart';
import '../../../../../core/providers/localization_provider.dart';
import '../providers/user_accounts_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _businessNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _nidController;
  late final TextEditingController _addressController;
  final _phoneInputKey = GlobalKey<PhoneInputFieldState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).value;
    _nameController = TextEditingController(text: user?.name ?? '');
    _businessNameController = TextEditingController(text: ''); // Will be set from user accounts
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: _removeCountryCode(user?.phoneNumber ?? ''));
    _nidController = TextEditingController(text: ''); // NID not in current user model
    _addressController = TextEditingController(text: user?.address ?? '');
  }

  String _removeCountryCode(String phoneNumber) {
    // Remove country code if it starts with 250 (Rwanda)
    if (phoneNumber.startsWith('250')) {
      return phoneNumber.substring(3);
    }
    return phoneNumber;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nidController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    print('🔧 EditProfileScreen: Starting _saveProfile...');
    if (!_formKey.currentState!.validate()) {
      print('🔧 EditProfileScreen: Form validation failed');
      return;
    }
    setState(() => _saving = true);
    
    try {
      final phoneInputState = _phoneInputKey.currentState;
      final fullPhoneNumber = phoneInputState?.fullPhoneNumber ?? _phoneController.text.trim();
      
      print('🔧 EditProfileScreen: Form data - name: ${_nameController.text.trim()}, email: ${_emailController.text.trim()}, phone: $fullPhoneNumber, address: ${_addressController.text.trim()}, businessName: ${_businessNameController.text.trim()}');
      
      await ref.read(authProvider.notifier).updateUserProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phoneNumber: fullPhoneNumber,
        address: _addressController.text.trim(),
        businessName: _businessNameController.text.trim().isEmpty ? null : _businessNameController.text.trim(),
      );
      
      print('🔧 EditProfileScreen: Profile update successful');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar(message: ref.read(localizationServiceProvider).translate('profileUpdatedSuccessfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('🔧 EditProfileScreen: Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar(message: ref.read(localizationServiceProvider).translate('failedToUpdateProfile')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationService = ref.watch(localizationServiceProvider);
    final authState = ref.watch(authProvider);
    final userAccountsState = ref.watch(userAccountsProvider);
    
    return authState.when(
      data: (user) {
        // Set business name from user accounts if available
        userAccountsState.whenData((userAccounts) {
          final defaultAccount = userAccounts.data.accounts.firstWhere(
            (account) => account.isDefault,
            orElse: () => userAccounts.data.accounts.first,
          );
          if (_businessNameController.text.isEmpty) {
            _businessNameController.text = defaultAccount.accountName;
          }
        });
        
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: CustomAppBar(
            title: localizationService.translate('editProfile'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Picture Section
                    Center(
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                        child: Icon(Icons.person, size: 48, color: AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing32),

                    // Full Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: localizationService.translate('fullName'),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizationService.translate('nameRequired');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing16),

                    // Business Name Field
                    TextFormField(
                      controller: _businessNameController,
                      decoration: InputDecoration(
                        labelText: localizationService.translate('businessName'),
                        prefixIcon: const Icon(Icons.business_outlined),
                        hintText: localizationService.translate('businessNameHint'),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizationService.translate('businessNameRequired');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing16),

                    // Email Field (Optional)
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: localizationService.translate('emailOptional'),
                        prefixIcon: const Icon(Icons.email_outlined),
                        hintText: localizationService.translate('emailHint'),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty && !value.contains('@')) {
                          return localizationService.translate('validEmailRequired');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing16),

                    // Phone Field
                    PhoneInputField(
                      key: _phoneInputKey,
                      controller: _phoneController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizationService.translate('phoneRequired');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing16),

                    // NID Field (Optional)
                    TextFormField(
                      controller: _nidController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: localizationService.translate('nationalIdOptional'),
                        prefixIcon: const Icon(Icons.badge_outlined),
                        hintText: localizationService.translate('nationalIdHint'),
                      ),
                      validator: (value) {
                        // NID is optional, so no validation required
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing16),

                    // Address Field
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: localizationService.translate('address'),
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        hintText: localizationService.translate('addressHint'),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.surfaceColor,
                          textStyle: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.surfaceColor))
                            : Text(localizationService.translate('saveChanges')),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
} 