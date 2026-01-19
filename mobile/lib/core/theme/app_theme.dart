import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF004AAD);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color sentMessageColor = Color(0xFFBBDEFB); // Medium light blue for sent messages
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF4CAF50); // Brighter green for success
  static const Color warningColor = Color(0xFFFFA000);
  static const Color chatBackground = Color(0xFFF5F6FA);
  // Removed infoColor (blue)

  // Text Colors
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF424242);
  static const Color textHintColor = Color(0xFF616161);

  // Snackbar Colors
  static const Color snackbarSuccessColor = Color(0xFF4CAF50);
  static const Color snackbarErrorColor = Color(0xFFE53935);
  static const Color snackbarWarningColor = Color(0xFFFFA000);
  static const Color snackbarInfoColor = Color(0xFF2196F3);
  static const Color snackbarNeutralColor = Color(0xFF424242);
  
  // Additional Colors
  static const Color infoColor = Color(0xFF2196F3);
  static const Color borderColor = Color(0xFFE0E0E0);

  // Spacing
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  
  // Action Sheet Spacing
  static const double actionSheetBottomSpacing = 16.0;
  static const Color thinBorderColor = Color(0xFFE0E0E0); // light gray
  static const double thinBorderWidth = 1.0;

  // Border Radius
  static const double borderRadius4 = 4.0;
  static const double borderRadius8 = 8.0;
  static const double borderRadius12 = 12.0;
  static const double borderRadius16 = 16.0;
  static const double borderRadius24 = 24.0;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;

  // Text Styles (using Inter font)
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: textPrimaryColor,
  );
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimaryColor,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: textPrimaryColor,
  );
  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );
  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimaryColor,
  );
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimaryColor,
  );
  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textPrimaryColor,
  );
  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textPrimaryColor,
  );
  static const TextStyle labelXSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );
  static const TextStyle badge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  // Snackbar Helper Methods
  static SnackBar successSnackBar({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: snackbarSuccessColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius8),
      ),
      margin: const EdgeInsets.all(spacing16),
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction ?? () {},
            )
          : null,
    );
  }

  static SnackBar errorSnackBar({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: snackbarErrorColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius8),
      ),
      margin: const EdgeInsets.all(spacing16),
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction ?? () {},
            )
          : null,
    );
  }

  static SnackBar warningSnackBar({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: snackbarWarningColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius8),
      ),
      margin: const EdgeInsets.all(spacing16),
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction ?? () {},
            )
          : null,
    );
  }

  static SnackBar infoSnackBar({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: snackbarInfoColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius8),
      ),
      margin: const EdgeInsets.all(spacing16),
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction ?? () {},
            )
          : null,
    );
  }

  static SnackBar neutralSnackBar({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: snackbarNeutralColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius8),
      ),
      margin: const EdgeInsets.all(spacing16),
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction ?? () {},
            )
          : null,
    );
  }

  static ThemeData get themeData => ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      headlineLarge: headlineLarge,
      bodyMedium: bodyMedium,
      titleMedium: titleMedium,
      bodySmall: bodySmall,
      labelSmall: badge,
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: primaryColor,
      secondary: primaryColor,
      error: errorColor,
      surface: Colors.white,
      onSurface: textPrimaryColor,
      // No blue/pink
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius8),
        borderSide: BorderSide(color: thinBorderColor, width: thinBorderWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius8),
        borderSide: BorderSide(color: thinBorderColor, width: thinBorderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius8),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius8),
        borderSide: BorderSide(color: errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius8),
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
      labelStyle: TextStyle(color: textSecondaryColor, fontFamily: 'Inter'),
      hintStyle: TextStyle(color: textHintColor, fontFamily: 'Inter'),
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    ),
    canvasColor: surfaceColor.withOpacity(0.98),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppTheme.surfaceColor,
      elevation: 0,
      indicatorColor: AppTheme.primaryColor.withOpacity(0.1),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }
        return const TextStyle(
          color: AppTheme.textSecondaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(
            color: AppTheme.primaryColor,
          );
        }
        return const IconThemeData(
          color: AppTheme.textSecondaryColor,
        );
      }),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textPrimaryColor),
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      surfaceTintColor: primaryColor,
    ),
  );
} 