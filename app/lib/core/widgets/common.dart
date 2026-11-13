import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme.dart';

/// Flat "floating" card with a soft ambient shadow (DESIGN.md mid layer).
class FloatingCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;

  const FloatingCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppRadius.lg,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: context.x.cardShadow,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}

/// Glassmorphic overlay used for AI suggestions (DESIGN.md overlay layer).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppRadius.lg,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: context.x.glassFill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: context.x.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Pill-shaped tag / filter chip.
class TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool caps;
  final VoidCallback? onTap;

  const TagChip({
    super.key,
    required this.label,
    this.selected = false,
    this.caps = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? context.cs.primary : context.x.chipBg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          caps ? label.toUpperCase() : label,
          style: TextStyle(
            fontSize: caps ? 11 : 14,
            fontWeight: FontWeight.w600,
            letterSpacing: caps ? 1.0 : 0.1,
            color: selected ? context.cs.onPrimary : context.cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// The little sparkle used to mark AI-generated content.
class AiSpark extends StatelessWidget {
  final double size;
  const AiSpark({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.auto_awesome, size: size, color: AppColors.accent);
  }
}

class LoadingView extends StatelessWidget {
  final String? label;
  const LoadingView({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: context.cs.onSurface, strokeWidth: 2),
          if (label != null) ...[
            const SizedBox(height: 16),
            Text(label!, style: context.tt.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: context.cs.outline),
            const SizedBox(height: 20),
            Text(title, style: context.tt.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(message, style: context.tt.bodyMedium, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

/// Simple shimmering placeholder block for skeleton loaders.
class Shimmer extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const Shimmer({super.key, this.width = double.infinity, this.height = 16, this.radius = 12});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * _c.value, 0),
              end: Alignment(1 - 2 * _c.value, 0),
              colors: [
                context.cs.surfaceContainerHigh,
                context.cs.surfaceContainer,
                context.cs.surfaceContainerHigh,
              ],
            ),
          ),
        );
      },
    );
  }
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: context.cs.surface)),
        backgroundColor: error ? AppColors.error : context.cs.onSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        margin: const EdgeInsets.all(16),
      ),
    );
}
