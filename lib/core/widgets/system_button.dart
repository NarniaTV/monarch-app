import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Botão estilizado no tema cyberpunk com efeitos visuais
class SystemButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDanger;
  final bool isLoading;
  final IconData? icon;

  const SystemButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = true,
    this.isDanger = false,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color glowColor;
    
    if (isDanger) {
      backgroundColor = AppColors.red;
      textColor = AppColors.white;
      glowColor = AppColors.red;
    } else if (isPrimary) {
      backgroundColor = AppColors.cyan;
      textColor = AppColors.black;
      glowColor = AppColors.cyan;
    } else {
      backgroundColor = Colors.transparent;
      textColor = AppColors.cyan;
      glowColor = AppColors.cyan;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        // Efeito de glow quando habilitado
        boxShadow: onPressed != null && !isLoading
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.2),
                  blurRadius: 25,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isPrimary || isDanger
                ? BorderSide.none
                : BorderSide(color: AppColors.cyan, width: 1.5),
          ),
          elevation: 0, // Removemos elevation padrão para usar nosso glow
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPrimary ? AppColors.black : AppColors.cyan,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      letterSpacing: 1.2,
                      shadows: isPrimary || isDanger
                          ? [
                              Shadow(
                                color: textColor.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
