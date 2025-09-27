import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/encryption_service.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/image_cache_service.dart';
import 'dart:io';
import 'dart:typed_data';

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
              ? FutureBuilder<Uint8List?>(
                  future: _loadDecryptedImage(imageUrl!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildPlaceholder(isDark);
                    }
                    if (snapshot.hasData && snapshot.data != null) {
                      return Image.memory(
                        snapshot.data!,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                      );
                    }
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

  /// Load and decrypt image from encrypted URL (with caching)
  Future<Uint8List?> _loadDecryptedImage(String imageUrl) async {
    try {
      // Initialize encryption for current user
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        debugPrint('❌ No user ID found for image decryption');
        return null;
      }
      
      // Security check: Verify URL belongs to current user
      if (!_isUrlForCurrentUser(imageUrl, userId)) {
        debugPrint('❌ Security violation: URL does not belong to current user');
        return null;
      }
      
      // Check cache first
      if (await ImageCacheService.instance.isCached(imageUrl)) {
        debugPrint('📱 Loading image from cache');
        return await ImageCacheService.instance.getCachedImage(imageUrl);
      }
      
      debugPrint('🌐 Loading image from Firebase Storage');
      await EncryptionService.instance.initialize(userId);
      
      // Download encrypted file
      final response = await HttpClient().getUrl(Uri.parse(imageUrl));
      final request = await response.close();
      final encryptedBytes = await request.fold<Uint8List>(
        Uint8List(0),
        (previous, element) => Uint8List.fromList([...previous, ...element]),
      );
      
      // Decrypt the image
      final decryptedBytes = await EncryptionService.instance.decryptFile(encryptedBytes);
      
      // Cache the decrypted image
      await ImageCacheService.instance.cacheImage(imageUrl, decryptedBytes);
      
      return decryptedBytes;
    } catch (e) {
      debugPrint('❌ Error loading decrypted image: $e');
      return null;
    }
  }

  /// Security check: Verify URL belongs to current user
  bool _isUrlForCurrentUser(String imageUrl, String userId) {
    try {
      // Check if URL contains the user's ID (handle both encoded and non-encoded paths)
      final expectedPath = 'users/$userId/profile-images/';
      final encodedPath = 'users%2F$userId%2Fprofile-images%2F';
      
      debugPrint('🔍 ProfileAvatar URL Security Check:');
      debugPrint('   Image URL: $imageUrl');
      debugPrint('   User ID: $userId');
      debugPrint('   Expected path: $expectedPath');
      debugPrint('   Encoded path: $encodedPath');
      debugPrint('   Contains check (normal): ${imageUrl.contains(expectedPath)}');
      debugPrint('   Contains check (encoded): ${imageUrl.contains(encodedPath)}');
      
      return imageUrl.contains(expectedPath) || imageUrl.contains(encodedPath);
    } catch (e) {
      debugPrint('❌ Error checking URL ownership: $e');
      return false;
    }
  }
} 