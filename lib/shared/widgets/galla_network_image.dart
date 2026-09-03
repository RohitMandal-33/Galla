import 'package:flutter/material.dart';
import '../../../core/theme/galla_theme.dart';

/// Production-grade remote image widget with:
/// - Exact memory dimension constraints (`cacheWidth`, `cacheHeight`)
/// - Smooth pulse/shimmer loading placeholder to prevent layout shifts
/// - Graceful offline & error handling with semantic fallback
/// - Border radius and aspect-ratio preservation
class GallaNetworkImage extends StatelessWidget {
  const GallaNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_outlined,
    this.fallbackColor,
    this.fallbackBgColor,
    this.cacheWidth,
    this.cacheHeight,
    this.overlayGradient,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final IconData fallbackIcon;
  final Color? fallbackColor;
  final Color? fallbackBgColor;
  final int? cacheWidth;
  final int? cacheHeight;
  final Gradient? overlayGradient;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = BorderRadius.circular(borderRadius);
    final fg = fallbackColor ?? GallaColors.brand;
    final bg = fallbackBgColor ?? GallaColors.brandSoft;

    Widget placeholder() {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: GallaColors.surface2,
          borderRadius: effectiveRadius,
        ),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: GallaColors.brand.withValues(alpha: 0.3),
            ),
          ),
        ),
      );
    }

    Widget errorFallback() {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: effectiveRadius,
          border: Border.all(color: GallaColors.line),
        ),
        child: Center(
          child: Icon(fallbackIcon, size: (height != null && height! < 50) ? 20 : 28, color: fg),
        ),
      );
    }

    if (imageUrl.trim().isEmpty) {
      return errorFallback();
    }

    // Default cache bounds to reasonable pixel sizes if unspecified
    final int effectiveCacheW = cacheWidth ?? (width != null ? (width! * 2).toInt() : 400);
    final int effectiveCacheH = cacheHeight ?? (height != null ? (height! * 2).toInt() : 400);

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Image.network(
            imageUrl,
            width: width,
            height: height,
            fit: fit,
            cacheWidth: effectiveCacheW > 0 ? effectiveCacheW : null,
            cacheHeight: effectiveCacheH > 0 ? effectiveCacheH : null,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return placeholder();
            },
            errorBuilder: (context, error, stackTrace) {
              return errorFallback();
            },
          ),
          if (overlayGradient != null)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: overlayGradient,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
