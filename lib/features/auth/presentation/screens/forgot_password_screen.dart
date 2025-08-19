import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:country_picker/country_picker.dart';
import '../../../../shared/utils/phone_validator.dart';
import '../../../../shared/utils/rwandan_phone_input_formatter.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'reset_password_screen.dart';
import 'login_screen.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/primary_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _codeSent = false;
  final bool _canResend = false;
  String? _error;
  int? _userId;
  bool _isPhoneReset = true; // Toggle between email and phone reset (default to phone)
  
  // Country picker for phone reset
  Country _selectedCountry = Country(
    phoneCode: '250',
    countryCode: 'RW',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'Rwanda',
    example: '250123456789',
    displayName: 'Rwanda (RW) [+250]',
    displayNameNoCountryCode: 'Rwanda (RW)',
    e164Key: '250-RW-0',
  );

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        flagSize: 25,
        backgroundColor: AppTheme.backgroundColor,
        textStyle: Theme.of(context).textTheme.bodyLarge!,
        bottomSheetHeight: 500,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Start typing to search',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFF8C98A8).withOpacity(0.2),
            ),
          ),
        ),
      ),
      countryFilter: const ['RW'], // Restrict to Rwanda only
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country;
        });
      },
    );
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    
    String phone = '';
    String email = '';
    
    if (_isPhoneReset) {
      phone = '+${_selectedCountry.phoneCode}${_phoneController.text.trim()}';
    } else {
      email = _emailController.text.trim();
    }
    
    if (phone.isEmpty && email.isEmpty) {
      setState(() {
        _error = 'Please enter either phone number or email';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final response = await ref.read(authProvider.notifier).requestPasswordReset(
        phone: phone.isNotEmpty ? phone : null,
        email: email.isNotEmpty ? email : null,
      );
      
      if (mounted) {
        setState(() {
          _codeSent = true;
          _userId = response['data']['user_id'];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar(message: 'Reset code sent successfully.'),
        );
        
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              userId: _userId!,
              phone: phone.isNotEmpty ? phone : null,
              email: email.isNotEmpty ? email : null,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar(message: _error ?? 'Failed to send reset code.'),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  'Forgot your password?',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  "Enter your phone number or email and we'll send you a reset code.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondaryColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing32),
                
                // Reset Method Toggle
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    border: Border.all(
                      color: AppTheme.thinBorderColor,
                      width: AppTheme.thinBorderWidth,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPhoneReset = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacing12,
                              horizontal: AppTheme.spacing16,
                            ),
                            decoration: BoxDecoration(
                              color: _isPhoneReset 
                                  ? Colors.grey[300] 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  color: _isPhoneReset 
                                      ? Colors.grey[700] 
                                      : AppTheme.textSecondaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: AppTheme.spacing8),
                                Text(
                                  'Phone',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: _isPhoneReset 
                                        ? Colors.grey[700] 
                                        : AppTheme.textSecondaryColor,
                                    fontWeight: _isPhoneReset 
                                        ? FontWeight.w600 
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPhoneReset = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacing12,
                              horizontal: AppTheme.spacing16,
                            ),
                            decoration: BoxDecoration(
                              color: !_isPhoneReset 
                                  ? Colors.grey[300] 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  color: !_isPhoneReset 
                                      ? Colors.grey[700] 
                                      : AppTheme.textSecondaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: AppTheme.spacing8),
                                Text(
                                  'Email',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: !_isPhoneReset 
                                        ? Colors.grey[700] 
                                        : AppTheme.textSecondaryColor,
                                    fontWeight: !_isPhoneReset 
                                        ? FontWeight.w600 
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),
                
                // Email or Phone Input Field
                if (!_isPhoneReset) ...[
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'your.email@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email address';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  // Phone Field with Country Code
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        // Country Code Picker
                        InkWell(
                          onTap: _showCountryPicker,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacing12,
                              vertical: AppTheme.spacing12,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                              border: Border.all(
                                color: AppTheme.thinBorderColor,
                                width: AppTheme.thinBorderWidth,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedCountry.flagEmoji,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(width: AppTheme.spacing4),
                                Text(
                                  '+${_selectedCountry.phoneCode}',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(width: AppTheme.spacing4),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: AppTheme.textSecondaryColor,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        // Phone Number Input
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              RwandanPhoneInputFormatter(),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone_outlined),
                              hintText: '788606765',
                            ),
                            validator: PhoneValidator.validateRwandanPhone,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                PrimaryButton(
                  label: 'Send Code',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _sendCode,
                ),
                if (_codeSent && !_isLoading)
                  Column(
                    children: [
                      const SizedBox(height: AppTheme.spacing16),
                      Text('If an account exists for this email, a reset code has been sent.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      TextButton(
                        onPressed: _canResend ? _sendCode : null,
                        child: Text(_canResend ? 'Resend Code' : 'Resend available in 30s'),
                      ),
                    ],
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