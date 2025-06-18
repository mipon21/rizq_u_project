import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'shimmer_widget.dart';

class CachedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;
  final Widget? placeholderWidget;
  final bool useShimmerForPlaceholder;
  final Color shimmerBaseColor;
  final Color shimmerHighlightColor;

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
    this.placeholderWidget,
    this.useShimmerForPlaceholder = true,
    this.shimmerBaseColor = const Color(0xFFEEEEEE),
    this.shimmerHighlightColor = const Color(0xFFF5F5F5),
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildErrorWidget();
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildPlaceholderWidget(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
        fadeInDuration: const Duration(milliseconds: 500),
        fadeOutDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Widget _buildPlaceholderWidget() {
    if (placeholderWidget != null) {
      return placeholderWidget!;
    }

    if (useShimmerForPlaceholder) {
      return ShimmerWidget.rectangular(
        width: width ?? double.infinity,
        height: height ?? 200,
        baseColor: shimmerBaseColor,
        highlightColor: shimmerHighlightColor,
      );
    }

    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (errorWidget != null) {
      return errorWidget!;
    }

    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey[400],
        size: ((width != null && height != null) &&
                (width!.isFinite && height!.isFinite) &&
                (width! > 0 && height! > 0))
            ? ((width! + height!) / 6).isFinite && ((width! + height!) / 6) > 0
                ? (width! + height!) / 6
                : 24
            : 24,
      ),
    );
  }
}

class CircularCachedImage extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Widget? errorWidget;
  final Widget? placeholderWidget;
  final bool useShimmerForPlaceholder;
  final BoxFit fit;

  const CircularCachedImage({
    super.key,
    required this.imageUrl,
    required this.radius,
    this.errorWidget,
    this.placeholderWidget,
    this.useShimmerForPlaceholder = true,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildErrorWidget();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: radius * 2,
        height: radius * 2,
        fit: fit,
        placeholder: (context, url) => _buildPlaceholderWidget(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
        fadeInDuration: const Duration(milliseconds: 500),
        fadeOutDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Widget _buildPlaceholderWidget() {
    if (placeholderWidget != null) {
      return placeholderWidget!;
    }

    if (useShimmerForPlaceholder) {
      return ShimmerWidget.circular(
        width: radius * 2,
        height: radius * 2,
      );
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (errorWidget != null) {
      return errorWidget!;
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey[400],
        size: (radius.isFinite && radius > 0) ? radius : 24,
      ),
    );
  }
}
