import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_keys_service.dart';
import '../../shared/models/api_key.dart';

final apiKeysServiceProvider = Provider<ApiKeysService>((ref) {
  return ApiKeysService();
});

final apiKeysProvider = FutureProvider<ApiKeysResponse>((ref) async {
  final service = ref.watch(apiKeysServiceProvider);
  return await service.getApiKeys();
});

final apiKeysNotifierProvider = StateNotifierProvider<ApiKeysNotifier, AsyncValue<ApiKeysResponse?>>((ref) {
  final service = ref.watch(apiKeysServiceProvider);
  return ApiKeysNotifier(service);
});

class ApiKeysNotifier extends StateNotifier<AsyncValue<ApiKeysResponse?>> {
  final ApiKeysService _service;

  ApiKeysNotifier(this._service) : super(const AsyncValue.loading());

  Future<void> fetchApiKeys() async {
    state = const AsyncValue.loading();
    try {
      final response = await _service.getApiKeys();
      state = AsyncValue.data(response);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<ApiKey> getApiKeys() {
    return state.value?.data.apiKeys ?? [];
  }

  ApiKey? getApiKeyByType(String keyType) {
    final keys = getApiKeys();
    return keys.where((key) => key.keyType == keyType && key.isActive).firstOrNull;
  }

  ApiKey? getOpenAIKey() {
    return getApiKeyByType('openai');
  }

  ApiKey? getAnthropicKey() {
    return getApiKeyByType('anthropic');
  }

  bool get hasApiKeys {
    return getApiKeys().isNotEmpty;
  }

  bool get hasOpenAIKey {
    return getOpenAIKey() != null;
  }

  bool get hasAnthropicKey {
    return getAnthropicKey() != null;
  }
}
