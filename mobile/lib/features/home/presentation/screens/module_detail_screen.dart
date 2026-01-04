import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/module.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ModuleDetailScreen extends ConsumerWidget {
  final AppModule module;

  const ModuleDetailScreen({
    super.key,
    required this.module,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(module.name),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
      ),
      body: CustomScrollView(
        slivers: [
          // Actions Section
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Actions',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Actions Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppTheme.spacing12,
                mainAxisSpacing: AppTheme.spacing12,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final action = module.actions[index];
                  return _ActionCard(action: action);
                },
                childCount: module.actions.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppTheme.spacing24),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final ModuleAction action;

  const _ActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
          border: Border.all(
            color: AppTheme.borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  ),
                  child: Icon(
                    action.icon,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                if (action.badge != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                      ),
                      child: Text(
                        action.badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              action.name,
              style: AppTheme.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.spacing4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
              child: Text(
                action.description,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

