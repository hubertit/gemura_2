import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/health_check_service.dart';

/// Backend health status
enum BackendHealthStatus {
  healthy,
  unhealthy,
  checking,
  unknown,
}

/// Backend health state
class BackendHealthState {
  final BackendHealthStatus status;
  final DateTime? lastCheckTime;
  final DateTime? lastHealthyTime;
  final int consecutiveFailures;
  final String? errorMessage;

  const BackendHealthState({
    required this.status,
    this.lastCheckTime,
    this.lastHealthyTime,
    this.consecutiveFailures = 0,
    this.errorMessage,
  });

  BackendHealthState copyWith({
    BackendHealthStatus? status,
    DateTime? lastCheckTime,
    DateTime? lastHealthyTime,
    int? consecutiveFailures,
    String? errorMessage,
  }) {
    return BackendHealthState(
      status: status ?? this.status,
      lastCheckTime: lastCheckTime ?? this.lastCheckTime,
      lastHealthyTime: lastHealthyTime ?? this.lastHealthyTime,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isHealthy => status == BackendHealthStatus.healthy;
  bool get isUnhealthy => status == BackendHealthStatus.unhealthy;
  bool get isChecking => status == BackendHealthStatus.checking;
}

/// Notifier for managing backend health checks
class HealthCheckNotifier extends StateNotifier<BackendHealthState> {
  Timer? _periodicTimer;
  bool _isCheckingInProgress = false;
  bool _isEnabled = true;

  // Configuration
  static const Duration checkInterval = Duration(minutes: 2); // Check every 2 minutes
  static const Duration checkIntervalOnFailure = Duration(seconds: 30); // Check every 30 seconds when unhealthy
  static const int maxConsecutiveFailuresBeforeAlert = 2; // Alert after 2 consecutive failures

  HealthCheckNotifier()
      : super(const BackendHealthState(
          status: BackendHealthStatus.unknown,
        ));

  /// Start periodic health checks
  void startPeriodicChecks() {
    if (!_isEnabled) return;
    
    // Stop any existing timer
    stopPeriodicChecks();
    
    // Perform initial check
    checkHealth();
    
    // Schedule periodic checks
    _scheduleNextCheck();
  }

  /// Stop periodic health checks
  void stopPeriodicChecks() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Pause health checks (e.g., when app goes to background)
  void pause() {
    _isEnabled = false;
    stopPeriodicChecks();
  }

  /// Resume health checks (e.g., when app comes to foreground)
  void resume() {
    _isEnabled = true;
    startPeriodicChecks();
  }

  /// Schedule the next health check based on current status
  void _scheduleNextCheck() {
    if (!_isEnabled) return;
    
    final interval = state.isUnhealthy 
        ? checkIntervalOnFailure 
        : checkInterval;
    
    _periodicTimer = Timer(interval, () {
      checkHealth();
      _scheduleNextCheck();
    });
  }

  /// Perform a health check
  Future<void> checkHealth() async {
    // Prevent concurrent checks
    if (_isCheckingInProgress) return;
    
    _isCheckingInProgress = true;
    
    // Update state to checking
    state = state.copyWith(
      status: BackendHealthStatus.checking,
      lastCheckTime: DateTime.now(),
    );

    try {
      // Perform health check with retry
      final isHealthy = await HealthCheckService.checkHealthWithRetry(
        maxRetries: 1, // Fewer retries for periodic checks
        retryDelay: const Duration(milliseconds: 500),
      );

      if (isHealthy) {
        // Backend is healthy
        state = BackendHealthState(
          status: BackendHealthStatus.healthy,
          lastCheckTime: DateTime.now(),
          lastHealthyTime: DateTime.now(),
          consecutiveFailures: 0,
          errorMessage: null,
        );
      } else {
        // Backend is unhealthy
        final newFailureCount = state.consecutiveFailures + 1;
        state = state.copyWith(
          status: BackendHealthStatus.unhealthy,
          lastCheckTime: DateTime.now(),
          consecutiveFailures: newFailureCount,
          errorMessage: 'Backend service is not responding',
        );
      }
    } catch (e) {
      // Error during health check
      final newFailureCount = state.consecutiveFailures + 1;
      state = state.copyWith(
        status: BackendHealthStatus.unhealthy,
        lastCheckTime: DateTime.now(),
        consecutiveFailures: newFailureCount,
        errorMessage: 'Health check failed: ${e.toString()}',
      );
    } finally {
      _isCheckingInProgress = false;
    }
  }

  /// Force an immediate health check
  Future<bool> forceCheck() async {
    await checkHealth();
    return state.isHealthy;
  }

  @override
  void dispose() {
    stopPeriodicChecks();
    super.dispose();
  }
}

/// Provider for backend health status
final healthCheckProvider =
    StateNotifierProvider<HealthCheckNotifier, BackendHealthState>((ref) {
  return HealthCheckNotifier();
});

/// Provider for checking if backend is healthy
final isBackendHealthyProvider = Provider<bool>((ref) {
  final healthState = ref.watch(healthCheckProvider);
  return healthState.isHealthy;
});

/// Provider for checking if we should show offline warning
final shouldShowOfflineWarningProvider = Provider<bool>((ref) {
  final healthState = ref.watch(healthCheckProvider);
  return healthState.consecutiveFailures >= 
      HealthCheckNotifier.maxConsecutiveFailuresBeforeAlert;
});
