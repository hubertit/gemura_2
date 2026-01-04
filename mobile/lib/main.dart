import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/config/secure_config.dart';
import 'core/services/secure_storage_service.dart';
import 'core/services/local_data_service.dart';
import 'core/providers/localization_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment variables
  await SecureConfig.initialize();
  
  // Initialize secure storage
  await SecureStorageService.initialize();
  
  // Initialize local data service
  await LocalDataService.initialize();
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
