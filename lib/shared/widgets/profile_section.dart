import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable section widget for profile screen
/// Follows Single Responsibility Principle - only handles section layout
class ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const ProfileSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        
        // Section Content Container
        Container(
          decoration: BoxDecoration(
            color: isDark 
              ? const Color(0xFF1C1C1E) 
              : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark 
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
            border: isDark 
              ? Border.all(
                  color: const Color(0xFF38383A),
                  width: 0.5,
                )
              : null,
          ),
          child: Column(
            children: _buildChildrenWithDividers(children, isDark),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildChildrenWithDividers(List<Widget> children, bool isDark) {
    final List<Widget> result = [];
    
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      
      // Add divider between items (except for the last item)
      if (i < children.length - 1) {
        result.add(
          Padding(
            padding: const EdgeInsets.only(left: 56), // Align with content
            child: Container(
              height: 0.5,
              color: isDark 
                ? const Color(0xFF38383A)
                : const Color(0xFFE5E5EA),
            ),
          ),
        );
      }
    }
    
    return result;
  }
} 