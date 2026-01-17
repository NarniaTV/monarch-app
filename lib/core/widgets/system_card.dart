import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Card estilizado no tema cyberpunk com efeitos de glow
class SystemCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? borderColor;
  final double? borderWidth;
  final VoidCallback? onTap;
  final bool showGlow;

  const SystemCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderColor,
    this.borderWidth,
    this.onTap,
    this.showGlow = false, // Efeito de glow opcional
  });

  @override
  Widget build(BuildContext context) {
    final color = borderColor ?? AppColors.cyan;
    
    Widget card = Container(
      margin: margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color,
          width: borderWidth ?? 1.5,
        ),
        // Efeito de glow sutil
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }

    return card;
  }
}
