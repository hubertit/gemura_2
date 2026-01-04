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
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8, horizontal: AppTheme.spacing8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: module.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              ),
              child: Icon(
                module.icon,
                color: module.color,
                size: 18,
              ),
            ),
            const SizedBox(height: AppTheme.spacing4),
            Text(
              module.name,
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

