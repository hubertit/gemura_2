import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../../../../shared/utils/snackbar_helper.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/primary_button.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final int userId;
  final String? phone;
  final String? email;
  const ResetPasswordScreen({
    super.key, 
    required this.userId,
    this.phone,
    this.email,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _error;
  String? _success;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });
    try {
      await ref.read(authProvider.notifier).resetPasswordWithCode(
        widget.userId,
        _codeController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      showIntentionSnackBar(
        context,
        'Your password has been reset. You can now log in.',
        intent: SnackBarIntent.success,
      );
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _error = errorMsg;
      });
      if (mounted) {
        showIntentionSnackBar(
          context,
          errorMsg,
          intent: SnackBarIntent.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Include at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Include at least one number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: 'Reset Password'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter the code sent to your ${widget.phone != null ? 'phone' : 'email'} and your new password.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                if (widget.phone != null || widget.email != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.phone ?? widget.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: AppTheme.spacing32),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Reset Code',
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.length != 6) {
                      return 'Enter the 6-digit code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacing16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: AppTheme.spacing16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacing24),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ),
                if (_success != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _success!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.successColor,
                      ),
                    ),
                  ),
                PrimaryButton(
                  label: 'Reset Password',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _resetPassword,
                ),
                const SizedBox(height: AppTheme.spacing24),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 