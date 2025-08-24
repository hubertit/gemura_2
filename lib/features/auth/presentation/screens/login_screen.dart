import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:country_picker/country_picker.dart';
import '../../../../shared/utils/phone_validator.dart';
import '../../../../shared/utils/rwandan_phone_input_formatter.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../../../shared/utils/snackbar_helper.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'package:dio/dio.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../home/presentation/screens/home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isPhoneLogin = true; // Toggle between email and phone login (default to phone)
  
  // Country picker for phone login
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

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateAfterLogin() {
    // Always navigate to home after login
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

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
      // Allow all countries
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country;
        });
      },
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      String identifier;
      if (_isPhoneLogin) {
        // Use phone with country code
        identifier = '+${_selectedCountry.phoneCode}${_phoneController.text.trim()}';
      } else {
        // Use email
        identifier = _emailController.text.trim();
      }
      
      await ref.read(authProvider.notifier).signInWithEmailAndPassword(
        identifier,
        _passwordController.text,
      );
      final user = ref.read(authProvider).value;
      if (mounted && user != null) {
        showIntentionSnackBar(
          context,
          'Login successful! Welcome back.',
          intent: SnackBarIntent.success,
        );
        _navigateAfterLogin();
      }
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Login failed. ';
      
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final backendMsg = e.response?.data?['message'] ?? e.message;
        
        switch (statusCode) {
          case 400:
            if (backendMsg?.contains('required') == true) {
              errorMessage = 'Please enter both email/phone and password.';
            } else {
              errorMessage += backendMsg ?? 'Invalid request. Please check your input.';
            }
            break;
          case 401:
            errorMessage = 'Invalid email/phone or password. Please try again.';
            break;
          case 403:
            errorMessage = 'Access denied. Please contact support.';
            break;
          case 404:
            errorMessage = 'Service not found. Please try again later.';
            break;
          case 422:
            errorMessage = 'Invalid data format. Please check your input.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          default:
            if (e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.sendTimeout) {
              errorMessage = 'Connection timeout. Please check your internet connection.';
            } else if (e.type == DioExceptionType.connectionError) {
              errorMessage = 'No internet connection. Please check your network.';
            } else {
              errorMessage += backendMsg ?? 'Please check your credentials and try again.';
            }
        }
      } else {
        errorMessage += e.toString();
      }
      
      showIntentionSnackBar(
        context,
        errorMessage,
        intent: SnackBarIntent.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and Title
                  Image.asset(
                    'assets/images/logo.png',
                    height: 80,
                  ),
                  const SizedBox(height: AppTheme.spacing24),
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    'Sign in to continue',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacing32),
                  
                  // Login Method Toggle
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
                                _isPhoneLogin = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppTheme.spacing12,
                                horizontal: AppTheme.spacing16,
                              ),
                              decoration: BoxDecoration(
                                color: _isPhoneLogin 
                                    ? Colors.grey[300] 
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    color: _isPhoneLogin 
                                        ? Colors.grey[700] 
                                        : AppTheme.textSecondaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppTheme.spacing8),
                                  Text(
                                    'Phone',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: _isPhoneLogin 
                                          ? Colors.grey[700] 
                                          : AppTheme.textSecondaryColor,
                                      fontWeight: _isPhoneLogin 
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
                                _isPhoneLogin = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppTheme.spacing12,
                                horizontal: AppTheme.spacing16,
                              ),
                              decoration: BoxDecoration(
                                color: !_isPhoneLogin 
                                    ? Colors.grey[300] 
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    color: !_isPhoneLogin 
                                        ? Colors.grey[700] 
                                        : AppTheme.textSecondaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppTheme.spacing8),
                                  Text(
                                    'Email',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: !_isPhoneLogin 
                                          ? Colors.grey[700] 
                                          : AppTheme.textSecondaryColor,
                                      fontWeight: !_isPhoneLogin 
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
                  if (!_isPhoneLogin) ...[
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
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
                              height: 56, // Match TextFormField height
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacing12,
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                PhoneInputFormatter(),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: const Icon(Icons.phone_outlined),
                                hintText: '788606765',
                                hintStyle: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor),
                              ),
                              validator: PhoneValidator.validateInternationalPhone,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacing16),
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing24),
                  // Login Button
                  PrimaryButton(
                    label: 'Sign In',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handleLogin,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account?',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: _navigateToRegister,
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 