import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../../../home/presentation/providers/tab_index_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(
      const Duration(milliseconds: AppConfig.splashDuration),
    );
    if (!mounted) return;
    
    // Check if user is already logged in
    final isLoggedIn = await ref.read(authProvider.notifier).isUserLoggedIn();
    
    if (!mounted) return;
    
    if (isLoggedIn) {
      // User is logged in, set default tab to chat and go to home screen
      ref.read(tabIndexProvider.notifier).state = 2; // Chat tab
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // User is not logged in, go to login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background cover image
          Image.asset(
            'assets/images/splash.jpg',
            fit: BoxFit.cover,
          ),
          // Loader in the center
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image(
                  image: AssetImage('assets/images/logo.png'),
                  width: 120,
                  height: 120,
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
          // Footer with more visible version and copyright
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Column(
              children: [
                Text(
                  '© ${DateTime.now().year} Gemura',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.surfaceColor,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Powered by RWANDA ICT Chamber',
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.surfaceColor,
                    shadows: [
                      Shadow(
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 