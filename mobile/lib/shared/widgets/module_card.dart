import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../models/module.dart';

class ModuleCard extends StatelessWidget {
  final AppModule module;
  final VoidCallback onTap;

  const ModuleCard({
    super.key,
    required this.module,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: module.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
              ),
              child: Icon(
                module.icon,
                color: module.color,
                size: 28,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              module.name,
              style: AppTheme.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.spacing4),
            Text(
              module.description,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

