import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lockflow/core/config/theme.dart';

class AppSkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const AppSkeletonLoader({
    Key? key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final highlightColor =
        isDark ? AppColors.darkOutline : AppColors.outline;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius:
              borderRadius ?? BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}

class AppSkeletonCard extends StatelessWidget {
  final int lineCount;
  final EdgeInsetsGeometry? padding;

  const AppSkeletonCard({
    Key? key,
    this.lineCount = 3,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.outline,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          lineCount,
          (index) => Padding(
            padding: EdgeInsets.only(
              bottom: index < lineCount - 1 ? 12.0 : 0,
            ),
            child: AppSkeletonLoader(
              height: 16,
              width: index == 0
                  ? double.infinity
                  : (index == lineCount - 1 ? 120 : 200),
            ),
          ),
        ),
      ),
    );
  }
}
