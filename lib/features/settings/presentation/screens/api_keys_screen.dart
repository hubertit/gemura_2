import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../core/providers/api_keys_provider.dart';
import '../../../../shared/models/api_key.dart';

class ApiKeysScreen extends ConsumerWidget {
  const ApiKeysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiKeysAsync = ref.watch(apiKeysProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'API Keys',
      ),
      body: apiKeysAsync.when(
        data: (response) => _buildApiKeysList(response.data.apiKeys),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                'Failed to load API keys',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                error.toString(),
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing16),
              ElevatedButton(
                onPressed: () => ref.refresh(apiKeysProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApiKeysList(List<ApiKey> apiKeys) {
    if (apiKeys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.key_off,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'No API keys found',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'API keys will appear here once configured',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: apiKeys.length,
      itemBuilder: (context, index) {
        final apiKey = apiKeys[index];
        return _buildApiKeyCard(apiKey);
      },
    );
  }

  Widget _buildApiKeyCard(ApiKey apiKey) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        border: Border.all(
          color: AppTheme.thinBorderColor,
          width: AppTheme.thinBorderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getKeyTypeIcon(apiKey.keyType),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        apiKey.keyName,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        _getKeyTypeDisplayName(apiKey.keyType),
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: apiKey.isActive 
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  ),
                  child: Text(
                    apiKey.isActive ? 'Active' : 'Inactive',
                    style: AppTheme.bodySmall.copyWith(
                      color: apiKey.isActive 
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                border: Border.all(
                  color: AppTheme.thinBorderColor,
                  width: AppTheme.thinBorderWidth,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.key,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: Text(
                      apiKey.keyValue,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Created: ${_formatDate(apiKey.createdAt)}',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getKeyTypeIcon(String keyType) {
    IconData iconData;
    Color iconColor;

    switch (keyType.toLowerCase()) {
      case 'openai':
        iconData = Icons.smart_toy;
        iconColor = Colors.green;
        break;
      case 'anthropic':
        iconData = Icons.psychology;
        iconColor = Colors.orange;
        break;
      case 'google':
        iconData = Icons.search;
        iconColor = Colors.blue;
        break;
      case 'azure':
        iconData = Icons.cloud;
        iconColor = Colors.blue;
        break;
      case 'aws':
        iconData = Icons.cloud_queue;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.key;
        iconColor = AppTheme.primaryColor;
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  String _getKeyTypeDisplayName(String keyType) {
    switch (keyType.toLowerCase()) {
      case 'openai':
        return 'OpenAI';
      case 'anthropic':
        return 'Anthropic Claude';
      case 'google':
        return 'Google AI';
      case 'azure':
        return 'Azure OpenAI';
      case 'aws':
        return 'AWS Bedrock';
      default:
        return keyType.toUpperCase();
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
