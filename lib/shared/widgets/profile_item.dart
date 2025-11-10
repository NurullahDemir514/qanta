import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable profile item widget
/// Follows Single Responsibility Principle - only handles individual item layout
/// Follows Open/Closed Principle - extensible through parameters
class ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Widget? trailing;

  const ProfileItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isInteractive = onTap != null;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark 
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? (isDark 
                    ? Colors.white.withValues(alpha: 0.9)
                    : const Color(0xFF6D6D70)),
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark 
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6D6D70),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Trailing
              if (trailing != null)
                trailing!
              else if (isInteractive)
                Icon(
                  Icons.chevron_right,
                  color: isDark 
                    ? Colors.white.withValues(alpha: 0.7)
                    : const Color(0xFF6D6D70),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
} 