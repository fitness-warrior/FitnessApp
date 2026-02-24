import 'package:flutter/material.dart';

/// Reusable card widget for displaying content with consistent styling
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double elevation;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const CustomCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation = 2.0,
    this.onTap,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: elevation,
      color: color,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: child,
      ),
    );

    return onTap != null
        ? InkWell(
            onTap: onTap,
            borderRadius: borderRadius ?? BorderRadius.circular(12.0),
            child: card,
          )
        : card;
  }
}
