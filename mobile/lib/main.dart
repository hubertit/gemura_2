import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/config/secure_config.dart';
import 'core/services/secure_storage_service.dart';
import 'core/providers/localization_provider.dart';
import 'core/providers/health_check_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment variables
  await SecureConfig.initialize();
  
  // Initialize secure storage
  await SecureStorageService.initialize();
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Start health checks after a short delay to allow app to initialize
    Future.delayed(const Duration(seconds: 2), () {
      ref.read(healthCheckProvider.notifier).startPeriodicChecks();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Handle app going to background
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Pause health checks to save battery and network
      ref.read(healthCheckProvider.notifier).pause();
    }
    
    // Handle app coming to foreground
    if (state == AppLifecycleState.resumed) {
      // Resume health checks
      ref.read(healthCheckProvider.notifier).resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(currentLocaleProvider);
    
    print('🌍 MyApp: Current locale is ${currentLocale.languageCode}');
    
    return MaterialApp(
      title: 'Gemura',
      theme: AppTheme.themeData,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      locale: currentLocale,
    );
  }
}
