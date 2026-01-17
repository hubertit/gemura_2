import 'package:flutter_riverpod/flutter_riverpod.dart';

final tabIndexProvider = StateProvider<int>((ref) => 0); // Default to home, will be set to chat if logged in 