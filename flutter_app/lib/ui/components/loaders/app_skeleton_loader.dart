import 'package:flutter/material.dart';
import '../../core/config/theme.dart';

class AppSkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const AppSkeletonLoader({
    Key? key,
    this.width = double.infinity,
    this.height = 16,
    BorderRadius? borderRadius,
  })  : borderRadius = borderRadius ?? const BorderRadius.all(Radius.circular(AppRadius.md)),
        super(key: key);

  @override
  State<AppSkeletonLoader> createState() => _AppSkeletonLoaderState();
}

class _AppSkeletonLoaderState extends State<AppSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant)
                    .withOpacity(0.1),
                (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant)
                    .withOpacity(0.3),
                (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant)
                    .withOpacity(0.1),
              ],
              stops: const [0, 0.5, 1],
              transform: GradientTransform.translate(
                Offset(_animation.value * bounds.width, 0),
              ),
            ).createShader(bounds);
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
              borderRadius: widget.borderRadius,
            ),
          ),
        );
      },
    );
  }
}

class AppSkeletonCard extends StatelessWidget {
  final int lineCount;
  final double lineHeight;
  final EdgeInsets padding;

  const AppSkeletonCard({
    Key? key,
    this.lineCount = 3,
    this.lineHeight = 12,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.outline,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          lineCount,
          (index) => Padding(
            padding: EdgeInsets.only(
              bottom: index < lineCount - 1 ? AppSpacing.md : 0,
            ),
            child: AppSkeletonLoader(
              height: lineHeight,
              width: index == lineCount - 1 ? 0.6 : double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}
