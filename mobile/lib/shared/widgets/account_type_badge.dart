import 'package:flutter/material.dart';
import '../models/user.dart';
import '../../core/theme/app_theme.dart';

class AccountTypeBadge extends StatelessWidget {
  final String accountType;
  final bool showIcon;
  final double? fontSize;
  final EdgeInsets? padding;
  final bool compact;

  const AccountTypeBadge({
    super.key,
    required this.accountType,
    this.showIcon = true,
    this.fontSize,
    this.padding,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = User.getAccountTypeDisplayName(accountType);
    final color = User.getAccountTypeColor(accountType);
    final icon = _getAccountTypeIcon(accountType);

    return Container(
      padding: padding ?? EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon && icon != null) ...[
            Icon(
              icon,
              size: compact ? 12 : 16,
              color: color,
            ),
            SizedBox(width: compact ? 4 : 6),
          ],
          Flexible(
            child: Text(
              displayName,
              style: AppTheme.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: fontSize ?? (compact ? 10 : 12),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData? _getAccountTypeIcon(String accountType) {
    switch (accountType.toLowerCase()) {
      case User.accountTypeMCC:
        return Icons.business;
      case User.accountTypeAgent:
        return Icons.person_outline;
      case User.accountTypeCollector:
        return Icons.local_shipping;
      case User.accountTypeVeterinarian:
        return Icons.medical_services;
      case User.accountTypeSupplier:
        return Icons.inventory;
      case User.accountTypeCustomer:
        return Icons.shopping_cart;
      case User.accountTypeFarmer:
        return Icons.agriculture;
      case User.accountTypeOwner:
        return Icons.person;
      default:
        return Icons.person;
    }
  }
}

// A simpler version for just text display
class AccountTypeText extends StatelessWidget {
  final String accountType;
  final TextStyle? style;
  final TextAlign? textAlign;

  const AccountTypeText({
    super.key,
    required this.accountType,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = User.getAccountTypeDisplayName(accountType);
    final color = User.getAccountTypeColor(accountType);

    return Text(
      displayName,
      style: (style ?? AppTheme.bodyMedium).copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
      textAlign: textAlign,
    );
  }
}
