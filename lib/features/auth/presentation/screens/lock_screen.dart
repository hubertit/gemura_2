import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/screens/home_screen.dart';
import 'forgot_password_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final List<String> _passcode = [];
  final String _correctPasscode = '1234'; // Replace with actual logic

  void _addDigit(String digit) {
    if (_passcode.length < 4) {
      setState(() {
        _passcode.add(digit);
      });
      if (_passcode.length == 4) _verifyPasscode();
    }
  }

  void _removeDigit() {
    if (_passcode.isNotEmpty) {
      setState(() {
        _passcode.removeLast();
      });
    }
  }

  void _verifyPasscode() {
    final entered = _passcode.join();
    if (entered == _correctPasscode) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() => _passcode.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(message: 'Incorrect passcode. Try again.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'User',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Login',
                    style: AppTheme.headlineLarge.copyWith(
                      color: AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your passcode',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < _passcode.length
                              ? AppTheme.primaryColor
                              : AppTheme.primaryColor.withOpacity(0.2),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            Expanded(
              flex: 4,
              child: Column(
                children: [
                  // Keypad grid (1-9)
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 65),
                      child: GridView.count(
                        crossAxisCount: 3,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: List.generate(9, (index) {
                          final number = (index + 1).toString();
                          return _buildNumberButton(number);
                        }),
                      ),
                    ),
                  ),

                  // Bottom row (Forgot, 0, Backspace)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                              );
                            },
                            child: Text(
                              'Forgot\npasscode?',
                              textAlign: TextAlign.center,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        _buildNumberButton('0'),
                        Expanded(child: _buildBackspaceButton()),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              flex: 1,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 100,
                    height: 1,
                    color: AppTheme.textHintColor.withOpacity(0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'OR',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textHintColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        AppTheme.infoSnackBar(message: 'Logout feature coming soon'),
                      );
                    },
                    child: Text(
                      'Log out',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _addDigit(number),
          borderRadius: BorderRadius.circular(65),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withOpacity(0.1),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            child: Center(
              child: Text(
                number,
                style: AppTheme.titleMedium.copyWith(
                  fontSize: 28,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Center(
      child: SizedBox(
        width: 80,
        height: 80,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _removeDigit,
            borderRadius: BorderRadius.circular(65),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.1),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
              ),
              child: const Center(
                child: Icon(Icons.backspace_outlined, size: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
