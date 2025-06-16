import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String userName;
  final double size;
  final bool showBorder;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    required this.userName,
    this.size = 64,
    this.showBorder = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 2),
          border: showBorder
              ? Border.all(
                  color: isDark
                      ? const Color(0xFF38383A)
                      : const Color(0xFFE5E5EA),
                  width: 2,
                )
              : null,
          boxShadow: showBorder
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? Image.network(
                  imageUrl!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildPlaceholder(isDark);
                  },
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('❌ Error loading profile image: $error');
                    return _buildPlaceholder(isDark);
                  },
                )
              : _buildPlaceholder(isDark),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2C2C2E)
            : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: GoogleFonts.inter(
            fontSize: size * 0.4, // Responsive font size
            fontWeight: FontWeight.w600,
            color: isDark
                ? const Color(0xFF8E8E93)
                : const Color(0xFF6D6D70),
          ),
        ),
      ),
    );
  }
} 