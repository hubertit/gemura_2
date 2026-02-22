import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Caches the last displayed net profit / balance for the home wallet card
/// so the amount does not jump from 0 while loading; it shows previous value then updates.
final homeWalletDisplayAmountProvider = StateProvider<double?>((ref) => null);
