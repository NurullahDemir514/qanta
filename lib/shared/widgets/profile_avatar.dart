import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/encryption_service.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/image_cache_service.dart';
import 'dart:io';
import 'dart:typed_data';

class ProfileAvatar extends StatefulWidget {
  final String? imageUrl;
  final String userName;
  final double size;
  final bool showBorder;
  final bool isPremium;
  final VoidCallback? onTap;
  final Key? tutorialKey; // Tutorial için key

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    required this.userName,
    this.size = 64,
    this.showBorder = false,
    this.isPremium = false,
    this.onTap,
    this.tutorialKey,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  Uint8List? _cachedImageData;
  String? _lastImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sadece imageUrl değiştiyse yeniden yükle
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      setState(() {
        _cachedImageData = null;
        _lastImageUrl = null;
      });
      return;
    }

    // Aynı URL ise tekrar yükleme
    if (_lastImageUrl == widget.imageUrl && _cachedImageData != null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _lastImageUrl = widget.imageUrl;
    });

    final imageData = await _loadDecryptedImage(widget.imageUrl!);

    if (mounted) {
      setState(() {
        _cachedImageData = imageData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium kullanıcılar için gradient border
    if (widget.isPremium && widget.showBorder) {
      return GestureDetector(
        key: widget.tutorialKey, // Tutorial key ekle
        onTap: widget.onTap,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.size / 2),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFD700), // Gold
                Color(0xFFFFA500), // Orange
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFA500).withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(1.5), // Border thickness (ince)
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular((widget.size - 3) / 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular((widget.size - 3) / 2),
              child: _isLoading
                  ? _buildPlaceholder(isDark)
                  : (_cachedImageData != null
                        ? _buildImageWidget(_cachedImageData!)
                        : _buildPlaceholder(isDark)),
            ),
          ),
        ),
      );
    }

    // Normal kullanıcılar için standart border
    return GestureDetector(
      key: widget.tutorialKey, // Tutorial key ekle
      onTap: widget.onTap,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.size / 2),
          border: widget.showBorder
              ? Border.all(
                  color: isDark
                      ? const Color(0xFF38383A)
                      : const Color(0xFFE5E5EA),
                  width: 2,
                )
              : null,
          boxShadow: widget.showBorder
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
          borderRadius: BorderRadius.circular(widget.size / 2),
          child: _isLoading
              ? _buildPlaceholder(isDark)
              : (_cachedImageData != null
                    ? _buildImageWidget(_cachedImageData!)
                    : _buildPlaceholder(isDark)),
        ),
      ),
    );
  }

  Widget _buildImageWidget(Uint8List imageData) {
    try {
      return Image.memory(
        imageData,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Image.memory error: $error');
          return _buildPlaceholder(Theme.of(context).brightness == Brightness.dark);
        },
      );
    } catch (e) {
      debugPrint('❌ Error building image widget: $e');
      return _buildPlaceholder(Theme.of(context).brightness == Brightness.dark);
    }
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(widget.size / 2),
      ),
      child: Center(
        child: Text(
          widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
          style: GoogleFonts.inter(
            fontSize: widget.size * 0.4, // Responsive font size
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
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
        final cachedData = await ImageCacheService.instance.getCachedImage(imageUrl);
        if (cachedData != null && _isValidImageData(cachedData)) {
          return cachedData;
        } else {
          // Remove invalid cached data
          await ImageCacheService.instance.removeCachedImage(imageUrl);
        }
      }
      await EncryptionService.instance.initialize(userId);

      // Download encrypted file
      final response = await HttpClient().getUrl(Uri.parse(imageUrl));
      final request = await response.close();
      final encryptedBytes = await request.fold<Uint8List>(
        Uint8List(0),
        (previous, element) => Uint8List.fromList([...previous, ...element]),
      );

      // Decrypt the image
      final decryptedBytes = await EncryptionService.instance.decryptFile(
        encryptedBytes,
      );

      // Validate decrypted image data
      if (decryptedBytes.isEmpty) {
        debugPrint('❌ Decrypted image data is empty');
        return null;
      }

      // Basic image format validation (check for common image headers)
      if (decryptedBytes.length < 4) {
        debugPrint('❌ Decrypted image data too short');
        return null;
      }

      // Check for common image format signatures
      final isValidImage = _isValidImageData(decryptedBytes);
      if (!isValidImage) {
        debugPrint('❌ Invalid image data format');
        return null;
      }

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


      return imageUrl.contains(expectedPath) || imageUrl.contains(encodedPath);
    } catch (e) {
      debugPrint('❌ Error checking URL ownership: $e');
      return false;
    }
  }

  /// Validate image data format
  bool _isValidImageData(Uint8List data) {
    if (data.length < 4) return false;
    
    // Check for common image format signatures
    // JPEG: FF D8 FF
    if (data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF) return true;
    
    // PNG: 89 50 4E 47
    if (data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47) return true;
    
    // GIF: 47 49 46 38
    if (data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x38) return true;
    
    // WebP: 52 49 46 46 (RIFF) + 57 45 42 50 (WEBP)
    if (data.length >= 12 && 
        data[0] == 0x52 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x46 &&
        data[8] == 0x57 && data[9] == 0x45 && data[10] == 0x42 && data[11] == 0x50) return true;
    
    return false;
  }
}
