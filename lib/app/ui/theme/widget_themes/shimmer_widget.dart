import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerWidget extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerWidget.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.baseColor = const Color(0xFFEEEEEE),
    this.highlightColor = const Color(0xFFF5F5F5),
  }) : shapeBorder = const RoundedRectangleBorder();

  const ShimmerWidget.circular({
    super.key,
    required this.width,
    required this.height,
    this.baseColor = const Color(0xFFEEEEEE),
    this.highlightColor = const Color(0xFFF5F5F5),
  }) : shapeBorder = const CircleBorder();

  ShimmerWidget.rounded({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.baseColor = const Color(0xFFEEEEEE),
    this.highlightColor = const Color(0xFFF5F5F5),
    double radius = 8,
  }) : shapeBorder = RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radius)),
        );

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          shape: shapeBorder,
          color: Colors.grey[300]!,
        ),
      ),
    );
  }
}

class ShimmerListView extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double spacing;
  final bool scrollable;

  const ShimmerListView({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.spacing = 16,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = List.generate(
      itemCount,
      (index) => Padding(
        padding: EdgeInsets.only(bottom: spacing),
        child: ShimmerWidget.rounded(
          height: itemHeight,
        ),
      ),
    );

    if (scrollable) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        children: items,
      );
    } else {
      return Column(
        children: items,
      );
    }
  }
}

class ShimmerGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double itemHeight;
  final double spacing;
  final double childAspectRatio;

  const ShimmerGrid({
    super.key,
    this.itemCount = 8,
    this.crossAxisCount = 2,
    this.itemHeight = 200,
    this.spacing = 16,
    this.childAspectRatio = 0.75,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return ShimmerWidget.rounded(
          height: itemHeight,
        );
      },
    );
  }
}

class ShimmerCard extends StatelessWidget {
  final double height;
  final double width;
  final bool showAvatar;
  final bool showContent;
  final int contentLines;

  const ShimmerCard({
    super.key,
    this.height = 120,
    this.width = double.infinity,
    this.showAvatar = true,
    this.showContent = true,
    this.contentLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAvatar)
            ShimmerWidget.circular(
              width: 40,
              height: 40,
            ),
          if (showAvatar) const SizedBox(width: 12),
          if (showContent)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerWidget.rounded(height: 18),
                  const SizedBox(height: 10),
                  ...List.generate(
                    contentLines,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ShimmerWidget.rounded(
                        height: 12,
                        width: (index == contentLines - 1)
                            ? width * 0.6
                            : width * 0.9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
