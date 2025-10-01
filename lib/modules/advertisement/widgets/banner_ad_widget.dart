import 'package:flutter/material.dart';
import '../contracts/advertisement_service_contract.dart';
import '../models/advertisement_models.dart';

/// Banner reklam widget'ı
/// SOLID - Single Responsibility Principle (SRP)
class BannerAdWidget extends StatefulWidget {
  final BannerAdvertisementServiceContract adService;
  final AdvertisementPosition position;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final bool showLoadingIndicator;
  final Widget? fallbackWidget;
  
  const BannerAdWidget({
    super.key,
    required this.adService,
    this.position = AdvertisementPosition.bottom,
    this.margin,
    this.padding,
    this.showLoadingIndicator = true,
    this.fallbackWidget,
  });
  
  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  @override
  void initState() {
    super.initState();
    _loadAd();
  }
  
  Future<void> _loadAd() async {
    await widget.adService.loadAd();
    if (mounted) {
      setState(() {});
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.adService.isLoading && widget.showLoadingIndicator) {
      return _buildLoadingIndicator();
    }
    
    if (widget.adService.error != null) {
      return _buildErrorWidget();
    }
    
    if (widget.adService.isLoaded && widget.adService.bannerWidget != null) {
      return _buildAdWidget();
    }
    
    return widget.fallbackWidget ?? const SizedBox.shrink();
  }
  
  Widget _buildLoadingIndicator() {
    return Container(
      width: double.infinity,
      height: widget.adService.bannerHeight,
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    );
  }
  
  Widget _buildErrorWidget() {
    return Container(
      width: double.infinity,
      height: widget.adService.bannerHeight,
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.grey[400],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              'Ad failed to load',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAdWidget() {
    return Container(
      width: double.infinity,
      height: widget.adService.bannerHeight, // Yükseklik kısıtlaması eklendi
      margin: widget.margin,
      padding: widget.padding,
      child: widget.adService.bannerWidget!,
    );
  }
}

/// Reklam pozisyonu için helper widget
class AdvertisementPositionedWidget extends StatelessWidget {
  final Widget child;
  final AdvertisementPosition position;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  
  const AdvertisementPositionedWidget({
    super.key,
    required this.child,
    required this.position,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });
  
  @override
  Widget build(BuildContext context) {
    switch (position) {
      case AdvertisementPosition.top:
        return Positioned(
          top: top ?? 0,
          left: left ?? 0,
          right: right ?? 0,
          child: child,
        );
      case AdvertisementPosition.bottom:
        return Positioned(
          bottom: bottom ?? 0,
          left: left ?? 0,
          right: right ?? 0,
          child: child,
        );
      case AdvertisementPosition.middle:
        return Center(child: child);
      case AdvertisementPosition.betweenContent:
        return child;
    }
  }
}
