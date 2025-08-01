import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../core/theme/app_theme.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _aboutController;
  late final TextEditingController _addressController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).value;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _aboutController = TextEditingController(text: user?.about ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _aboutController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await ref.read(authProvider.notifier).updateUserProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      about: _aboutController.text.trim(),
      address: _addressController.text.trim(),
    );
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.successSnackBar(message: 'Profile updated successfully!'),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    return authState.when(
      data: (user) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Profile'),
            backgroundColor: AppTheme.surfaceColor,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
            titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                      child: Icon(Icons.person, size: 48, color: AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text('Add photo', style: AppTheme.bodyMedium.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 24),
                  _ProfileFieldCard(
                    label: 'Full Name',
                    controller: _nameController,
                    icon: Icons.person_outline,
                    validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
                  ),
                  _ProfileFieldCard(
                    label: 'Email',
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    validator: (value) => value == null || value.trim().isEmpty ? 'Email is required' : null,
                  ),
                  _ProfileFieldCard(
                    label: 'Phone Number',
                    controller: _phoneController,
                    icon: Icons.phone,
                    validator: (value) => value == null || value.trim().isEmpty ? 'Phone is required' : null,
                    keyboardType: TextInputType.phone,
                  ),
                  _ProfileFieldCard(
                    label: 'About',
                    controller: _aboutController,
                    icon: Icons.info_outline,
                    maxLines: 3,
                  ),
                  _ProfileFieldCard(
                    label: 'Address',
                    controller: _addressController,
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
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
                            : const Text('Save Changes'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }
}

class _ProfileFieldCard extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;
  const _ProfileFieldCard({
    required this.label,
    required this.controller,
    required this.icon,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextFormField(
            controller: controller,
            validator: validator,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
              prefixIcon: Icon(icon, color: AppTheme.primaryColor),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }
} 