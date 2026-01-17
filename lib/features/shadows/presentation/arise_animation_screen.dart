import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../models/shadow_model.dart';

/// Tela de animação épica "ARISE" ao extrair uma sombra
class AriseAnimationScreen extends StatefulWidget {
  final ShadowModel shadow;

  const AriseAnimationScreen({
    super.key,
    required this.shadow,
  });

  @override
  State<AriseAnimationScreen> createState() => _AriseAnimationScreenState();
}

class _AriseAnimationScreenState extends State<AriseAnimationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _glowController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Animação de fade do background
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Animação de glow pulsante
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Animação de escala (surge from below)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Animação de rotação sutil
    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Inicia animações em sequência
    _fadeController.forward().then((_) {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _glowController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shadowColor = Color(widget.shadow.getColorValue());
    final isGolden = widget.shadow.type == 'objective' && 
                     widget.shadow.objectiveRank?.name == 's';

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _fadeController,
          _glowController,
          _scaleController,
          _rotationController,
        ]),
        builder: (context, child) {
          return Stack(
            children: [
              // Background radial gradient com animação
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      shadowColor.withValues(alpha: _fadeAnimation.value * 0.3),
                      Colors.black,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),

              // Efeito de scanlines
              if (_fadeAnimation.value > 0.5)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: CustomPaint(
                      painter: ScanlinePainter(),
                    ),
                  ),
                ),

              // Círculos concêntricos rotativos
              Center(
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: shadowColor.withValues(alpha: _glowAnimation.value * 0.3),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              
              Center(
                child: Transform.rotate(
                  angle: -_rotationAnimation.value * 1.5,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: shadowColor.withValues(alpha: _glowAnimation.value * 0.5),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

              // Conteúdo principal
              Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Título "ARISE" ou "ETERNAL" (se for objetivo S)
                      Text(
                        isGolden ? 'ETERNAL' : 'ARISE',
                        style: GoogleFonts.orbitron(
                          fontSize: isGolden ? 64 : 72,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 12,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: shadowColor.withValues(alpha: _glowAnimation.value),
                              blurRadius: 40,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Ícone/símbolo da sombra
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: shadowColor.withValues(alpha: 0.2),
                          boxShadow: [
                            BoxShadow(
                              color: shadowColor.withValues(alpha: _glowAnimation.value * 0.8),
                              blurRadius: 60,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isGolden ? Icons.emoji_events : Icons.psychology_alt,
                            size: 64,
                            color: shadowColor,
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Nome da sombra
                      Text(
                        widget.shadow.getEpicName(),
                        style: GoogleFonts.orbitron(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: shadowColor,
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Subtítulo com nome original
                      if (widget.shadow.name != widget.shadow.getEpicName())
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            '"${widget.shadow.name}"',
                            style: GoogleFonts.shareTechMono(
                              fontSize: 14,
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Estatísticas da sombra
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 48),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          border: Border.all(
                            color: shadowColor.withValues(alpha: 0.5),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildStatRow('XP BOOST', '+${widget.shadow.xpBonus}%', shadowColor),
                            const SizedBox(height: 12),
                            _buildStatRow('EFICIÊNCIA', '+${widget.shadow.efficiencyBonus}%', shadowColor),
                            if (widget.shadow.statType != null) ...[
                              const SizedBox(height: 12),
                              _buildStatRow('TIPO', widget.shadow.statType!.name.toUpperCase(), shadowColor),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Botão continuar (só aparece após animação completar)
                      if (_scaleAnimation.value > 0.9)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: shadowColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 48,
                                vertical: 16,
                              ),
                              shape: const BeveledRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                              ),
                            ),
                            child: Text(
                              'CONTINUAR',
                              style: GoogleFonts.orbitron(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.shareTechMono(
            fontSize: 12,
            color: Colors.white70,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

/// Painter para efeito de scanlines
class ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.height; i += 4) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
