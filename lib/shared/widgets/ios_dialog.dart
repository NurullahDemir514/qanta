import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IOSDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final List<IOSDialogAction> actions;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  const IOSDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    required this.actions,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 270,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            
            // Icon (optional)
            if (icon != null) ...[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: (iconBackgroundColor ?? const Color(0xFF8E8E93)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: iconColor ?? const Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Message or Content
            if (message != null || content != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: content ?? Text(
                  message!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF8E8E93),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Actions
            if (actions.length == 1) ...[
              // Single action
              _buildSingleAction(context, isDark, actions.first),
            ] else if (actions.length == 2) ...[
              // Two actions (side by side)
              _buildTwoActions(context, isDark, actions),
            ] else ...[
              // Multiple actions (stacked)
              _buildMultipleActions(context, isDark, actions),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSingleAction(BuildContext context, bool isDark, IOSDialogAction action) {
    return Column(
      children: [
        // Divider
        Container(
          height: 0.33,
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6),
        ),
        
        // Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (action.onPressed != null) {
                action.onPressed!();
              } else {
                Navigator.of(context).pop();
              }
            },
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            splashColor: action.isPrimary 
              ? const Color(0xFF007AFF).withValues(alpha: 0.08)
              : (action.isDestructive 
                  ? const Color(0xFFFF3B30).withValues(alpha: 0.08)
                  : Colors.grey.withValues(alpha: 0.08)),
            highlightColor: Colors.transparent,
            child: Container(
              width: double.infinity,
              height: 44,
              alignment: Alignment.center,
              child: Text(
                action.text,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: action.isPrimary ? FontWeight.w600 : (action.isDestructive ? FontWeight.w500 : FontWeight.w400),
                  color: action.isDestructive 
                    ? const Color(0xFFFF3B30)
                    : (action.isPrimary 
                        ? const Color(0xFF007AFF)
                        : const Color(0xFF8E8E93)),
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTwoActions(BuildContext context, bool isDark, List<IOSDialogAction> actions) {
    return Column(
      children: [
        // Divider
        Container(
          height: 0.33,
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6),
        ),
        
        // Buttons
        Row(
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (actions[0].onPressed != null) {
                      actions[0].onPressed!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                  ),
                  splashColor: actions[0].isPrimary 
                    ? const Color(0xFF007AFF).withValues(alpha: 0.08)
                    : (actions[0].isDestructive 
                        ? const Color(0xFFFF3B30).withValues(alpha: 0.08)
                        : Colors.grey.withValues(alpha: 0.08)),
                  highlightColor: Colors.transparent,
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    child: Text(
                      actions[0].text,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: actions[0].isPrimary ? FontWeight.w600 : (actions[0].isDestructive ? FontWeight.w500 : FontWeight.w400),
                        color: actions[0].isDestructive 
                          ? const Color(0xFFFF3B30)
                          : (actions[0].isPrimary 
                              ? const Color(0xFF007AFF)
                              : const Color(0xFF8E8E93)),
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Vertical divider
            Container(
              width: 0.33,
              height: 44,
              color: isDark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6),
            ),
            
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (actions[1].onPressed != null) {
                      actions[1].onPressed!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(14),
                  ),
                  splashColor: actions[1].isPrimary 
                    ? const Color(0xFF007AFF).withValues(alpha: 0.08)
                    : (actions[1].isDestructive 
                        ? const Color(0xFFFF3B30).withValues(alpha: 0.08)
                        : Colors.grey.withValues(alpha: 0.08)),
                  highlightColor: Colors.transparent,
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    child: Text(
                      actions[1].text,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: actions[1].isPrimary ? FontWeight.w600 : (actions[1].isDestructive ? FontWeight.w500 : FontWeight.w400),
                        color: actions[1].isDestructive 
                          ? const Color(0xFFFF3B30)
                          : (actions[1].isPrimary 
                              ? const Color(0xFF007AFF)
                              : const Color(0xFF8E8E93)),
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMultipleActions(BuildContext context, bool isDark, List<IOSDialogAction> actions) {
    return Column(
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          // Divider
          Container(
            height: 0.33,
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6),
          ),
          
          // Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (actions[i].onPressed != null) {
                  actions[i].onPressed!();
                } else {
                  Navigator.of(context).pop();
                }
              },
              borderRadius: i == actions.length - 1 
                ? const BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  )
                : null,
              splashColor: actions[i].isPrimary 
                ? const Color(0xFF007AFF).withValues(alpha: 0.08)
                : (actions[i].isDestructive 
                    ? const Color(0xFFFF3B30).withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.08)),
              highlightColor: Colors.transparent,
              child: Container(
                width: double.infinity,
                height: 44,
                alignment: Alignment.center,
                child: Text(
                  actions[i].text,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: actions[i].isPrimary ? FontWeight.w600 : (actions[i].isDestructive ? FontWeight.w500 : FontWeight.w400),
                    color: actions[i].isDestructive 
                      ? const Color(0xFFFF3B30)
                      : (actions[i].isPrimary 
                          ? const Color(0xFF007AFF)
                          : const Color(0xFF8E8E93)),
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Show iOS-style dialog
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? message,
    Widget? content,
    required List<IOSDialogAction> actions,
    IconData? icon,
    Color? iconColor,
    Color? iconBackgroundColor,
    bool barrierDismissible = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => IOSDialog(
        title: title,
        message: message,
        content: content,
        actions: actions,
        icon: icon,
        iconColor: iconColor,
        iconBackgroundColor: iconBackgroundColor,
      ),
    );
  }
}

class IOSDialogAction {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;

  const IOSDialogAction({
    required this.text,
    this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });
} 