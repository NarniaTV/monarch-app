import 'dart:ui';
import 'package:flutter/material.dart';

/// Background Tático HUD reutilizável
/// Inclui: Imagem desfocada + Vignette + Scanlines
class TacticalBackground extends StatelessWidget {
  const TacticalBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // LAYER 1: Background com Blur e Vignette
        _buildAtmosphere(),

        // LAYER 2: Scanline Overlay
        _buildScanlineOverlay(),
      ],
    );
  }

  /// ATMOSPHERE: Background + Blur + Vignette
  Widget _buildAtmosphere() {
    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/images/login_bg.avif',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0A0A1A),
                      const Color(0xFF1A0A2A),
                      const Color(0xFF0A0A1A),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Blur Effect
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(color: Colors.transparent),
          ),
        ),

        // Black Overlay
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.6),
          ),
        ),

        // Vignette (RadialGradient)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black,
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// SCANLINE OVERLAY: CRT Monitor Effect
  Widget _buildScanlineOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: List.generate(
                100,
                (index) => index.isEven
                    ? Colors.black.withValues(alpha: 0.05)
                    : Colors.transparent,
              ),
              stops: List.generate(100, (index) => index / 100),
            ),
          ),
        ),
      ),
    );
  }
}
