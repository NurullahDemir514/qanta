import 'package:flutter/material.dart';

/// Gift Card Provider Enum
/// Represents different gift card providers
enum GiftCardProvider {
  amazon('amazon', 'Amazon'),
  paribu('paribu', 'Paribu Cineverse'),
  dnr('dnr', 'D&R'),
  gratis('gratis', 'Gratis');

  const GiftCardProvider(this.value, this.displayName);
  final String value;
  final String displayName;

  static GiftCardProvider fromString(String value) {
    return GiftCardProvider.values.firstWhere(
      (provider) => provider.value == value,
      orElse: () => GiftCardProvider.amazon,
    );
  }
}

/// Gift Card Provider Configuration
/// Configuration for each gift card provider
class GiftCardProviderConfig {
  final GiftCardProvider provider;
  final String name;
  final String description;
  final double minimumThreshold; // Minimum TL amount
  final double giftCardAmount; // Gift card amount in TL
  final String iconPath; // Asset path for icon
  final Color primaryColor; // Primary color for this provider
  final Color accentColor; // Accent color for this provider
  final bool enabled; // Is this provider enabled?

  const GiftCardProviderConfig({
    required this.provider,
    required this.name,
    required this.description,
    required this.minimumThreshold,
    required this.giftCardAmount,
    required this.iconPath,
    required this.primaryColor,
    required this.accentColor,
    this.enabled = true,
  });

  /// Get required points for this provider (200 points = 1 TL)
  int get requiredPoints => (minimumThreshold * 200).toInt();

  /// Get progress percentage (0.0 to 1.0) based on current points
  double getProgress(int currentPoints) {
    if (requiredPoints <= 0) return 0.0;
    return (currentPoints / requiredPoints).clamp(0.0, 1.0);
  }

  /// Get remaining points needed
  int getRemainingPoints(int currentPoints) {
    return (requiredPoints - currentPoints).clamp(0, requiredPoints);
  }

  /// Check if user can redeem for this provider
  bool canRedeem(int currentPoints) {
    return currentPoints >= requiredPoints;
  }

  /// Get number of gift cards user can redeem
  int getAvailableGiftCards(int currentPoints) {
    if (!canRedeem(currentPoints)) return 0;
    return (currentPoints / requiredPoints).floor();
  }

  /// Create from Remote Config (future implementation)
  factory GiftCardProviderConfig.fromRemoteConfig(
    GiftCardProvider provider,
    Map<String, dynamic> config,
  ) {
    // This will be implemented to read from Remote Config
    // For now, return default configs
    return _getDefaultConfig(provider);
  }

  /// Get default configuration for provider
  static GiftCardProviderConfig _getDefaultConfig(GiftCardProvider provider) {
    switch (provider) {
      case GiftCardProvider.amazon:
        return const GiftCardProviderConfig(
          provider: GiftCardProvider.amazon,
          name: 'Amazon',
          description: 'Amazon.com.tr\'den alışveriş yapın',
          minimumThreshold: 100.0,
          giftCardAmount: 100.0,
          iconPath: 'assets/images/amazon_logo_new.png',
          primaryColor: Color(0xFFFF9900), // Amazon Orange (#FF9900)
          accentColor: Color(0xFFFF7700), // Darker orange
          enabled: true,
        );
      case GiftCardProvider.paribu:
        return const GiftCardProviderConfig(
          provider: GiftCardProvider.paribu,
          name: 'Paribu Cineverse',
          description: 'Sinema bileti paketleri için',
          minimumThreshold: 500.0,
          giftCardAmount: 500.0,
          iconPath: 'assets/images/paribu_logo.png',
          primaryColor: Color(0xFF00C853), // Paribu Cineverse Green (#00C853) - Vibrant green
          accentColor: Color(0xFF00A844), // Darker green for gradients
          enabled: true,
        );
      case GiftCardProvider.dnr:
        return const GiftCardProviderConfig(
          provider: GiftCardProvider.dnr,
          name: 'D&R',
          description: 'Kitap, müzik ve eğlence',
          minimumThreshold: 100.0,
          giftCardAmount: 100.0,
          iconPath: 'assets/images/dnr_logo.png',
          primaryColor: Color(0xFF0057A6), // D&R Blue (#0057A6) - Official brand color
          accentColor: Color(0xFF003F7F), // Darker blue for gradients
          enabled: true,
        );
      case GiftCardProvider.gratis:
        return const GiftCardProviderConfig(
          provider: GiftCardProvider.gratis,
          name: 'Gratis',
          description: 'Kozmetik ve kişisel bakım',
          minimumThreshold: 100.0,
          giftCardAmount: 100.0,
          iconPath: 'assets/images/gratis_logo.png',
          primaryColor: Color(0xFF6E0D8E), // Gratis Purple (#6E0D8E)
          accentColor: Color(0xFF5A0A73), // Darker purple
          enabled: true,
        );
    }
  }

  /// Get all enabled providers
  static List<GiftCardProviderConfig> getEnabledProviders() {
    return GiftCardProvider.values
        .map((provider) => _getDefaultConfig(provider))
        .where((config) => config.enabled)
        .toList();
  }

  /// Get provider config by ID (string)
  static GiftCardProviderConfig? getProviderById(String providerId) {
    try {
      final provider = GiftCardProvider.fromString(providerId);
      return _getDefaultConfig(provider);
    } catch (e) {
      return null;
    }
  }
}

