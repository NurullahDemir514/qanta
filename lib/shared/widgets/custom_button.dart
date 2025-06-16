import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';

enum ButtonVariant {
  primary,
  secondary,
  outline,
  text,
}

enum ButtonSize {
  small,
  medium,
  large,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final Color? customColor;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null && !isLoading;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: _getHeight(),
      child: _buildButton(context, theme, isEnabled),
    );
  }

  Widget _buildButton(BuildContext context, ThemeData theme, bool isEnabled) {
    switch (variant) {
      case ButtonVariant.primary:
        return ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: _getPrimaryStyle(theme),
          child: _buildContent(context, theme.colorScheme.onPrimary),
        );
      case ButtonVariant.secondary:
        return ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: _getSecondaryStyle(theme),
          child: _buildContent(context, theme.colorScheme.onSecondary),
        );
      case ButtonVariant.outline:
        return OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: _getOutlineStyle(theme),
          child: _buildContent(context, customColor ?? AppConstants.primaryColor),
        );
      case ButtonVariant.text:
        return TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: _getTextStyle(theme),
          child: _buildContent(context, customColor ?? AppConstants.primaryColor),
        );
    }
  }

  Widget _buildContent(BuildContext context, Color textColor) {
    if (isLoading) {
      return SizedBox(
        width: _getIconSize(),
        height: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == ButtonVariant.primary 
              ? Colors.white
              : (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF6D6D70)),
          ),
        ),
      );
    }

    final textWidget = Text(
      text,
      style: GoogleFonts.inter(
        fontSize: _getFontSize(),
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: _getIconSize(),
            color: textColor,
          ),
          SizedBox(width: AppConstants.spacingS),
          textWidget,
        ],
      );
    }

    return textWidget;
  }

  ButtonStyle _getPrimaryStyle(ThemeData theme) {
    return ElevatedButton.styleFrom(
      backgroundColor: customColor ?? AppConstants.primaryColor,
      foregroundColor: Colors.white,
      elevation: AppConstants.cardElevation,
      padding: _getPadding(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
    );
  }

  ButtonStyle _getSecondaryStyle(ThemeData theme) {
    return ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.secondary,
      foregroundColor: theme.colorScheme.onSecondary,
      elevation: AppConstants.cardElevation,
      padding: _getPadding(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
    );
  }

  ButtonStyle _getOutlineStyle(ThemeData theme) {
    return OutlinedButton.styleFrom(
      foregroundColor: customColor ?? AppConstants.primaryColor,
      side: BorderSide(
        color: customColor ?? AppConstants.primaryColor,
        width: 1.5,
      ),
      padding: _getPadding(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
    );
  }

  ButtonStyle _getTextStyle(ThemeData theme) {
    return TextButton.styleFrom(
      foregroundColor: customColor ?? AppConstants.primaryColor,
      padding: _getPadding(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        );
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingL,
          vertical: AppConstants.spacingM,
        );
      case ButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingXL,
          vertical: AppConstants.spacingL,
        );
    }
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return 36.0;
      case ButtonSize.medium:
        return AppConstants.buttonHeight;
      case ButtonSize.large:
        return 56.0;
    }
  }

  double _getFontSize() {
    switch (size) {
      case ButtonSize.small:
        return 14.0;
      case ButtonSize.medium:
        return 16.0;
      case ButtonSize.large:
        return 18.0;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16.0;
      case ButtonSize.medium:
        return 20.0;
      case ButtonSize.large:
        return 24.0;
    }
  }
} 