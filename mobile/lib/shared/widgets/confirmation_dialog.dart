import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Reusable confirmation dialog with consistent styling
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final IconData? icon;
  final Color? iconColor;
  final bool showIcon;
  final bool isLoading;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.icon,
    this.iconColor,
    this.showIcon = true,
    this.isLoading = false,
  });

  /// Show a confirmation dialog and return true if confirmed, false otherwise
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
    IconData? icon,
    Color? iconColor,
    bool showIcon = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        icon: icon,
        iconColor: iconColor,
        showIcon: showIcon,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
    return result ?? false;
  }

  /// Show a destructive confirmation dialog (for delete actions)
  static Future<bool> showDelete({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
  }) async {
    return show(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText ?? 'Delete',
      cancelText: cancelText ?? 'Cancel',
      isDestructive: true,
      icon: Icons.warning_amber_rounded,
      iconColor: AppTheme.errorColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
      ),
      title: Text(
        title,
        style: AppTheme.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimaryColor,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon && icon != null) ...[
            Icon(
              icon,
              size: 48,
              color: iconColor ?? (isDestructive ? AppTheme.errorColor : AppTheme.warningColor),
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],
          Text(
            message,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : (onCancel ?? () => Navigator.of(context).pop(false)),
          child: Text(
            cancelText ?? 'Cancel',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
        if (isDestructive)
          ElevatedButton(
            onPressed: isLoading ? null : (onConfirm ?? () => Navigator.of(context).pop(true)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.surfaceColor,
                    ),
                  )
                : Text(
                    confirmText ?? 'Delete',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.surfaceColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          )
        else
          TextButton(
            onPressed: isLoading ? null : (onConfirm ?? () => Navigator.of(context).pop(true)),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : Text(
                    confirmText ?? 'Confirm',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
      ],
    );
  }
}
