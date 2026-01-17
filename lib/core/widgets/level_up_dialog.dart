import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../theme/app_colors.dart';

/// Dialog comemorativo de Level Up com animação
class LevelUpDialog extends StatefulWidget {
  final int newLevel;
  final int xpGained;

  const LevelUpDialog({
    super.key,
    required this.newLevel,
    required this.xpGained,
  });

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();

  /// Mostra o dialog de level up
  static void show(BuildContext context, int newLevel, int xpGained) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LevelUpDialog(
        newLevel: newLevel,
        xpGained: xpGained,
      ),
    );
  }
}

class _LevelUpDialogState extends State<LevelUpDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getMotivationalMessage(int level) {
    final messages = [
      'Seu poder está crescendo!',
      'Você está mais forte!',
      'Evolução detectada!',
      'Nível de poder aumentado!',
      'Você está ascendendo!',
      'Seu potencial se expande!',
      'Força interior desbloqueada!',
      'Você transcendeu seus limites!',
      'Poder absoluto em crescimento!',
      'Sua jornada continua!',
    ];

    if (level == 10) return 'Primeiro marco alcançado!';
    if (level == 25) return 'Você está imparável!';
    if (level == 50) return 'Metade da jornada completa!';
    if (level == 100) return 'LENDÁRIO! Nível 100!';
    
    return messages[level % messages.length];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1115),
                border: Border.all(
                  color: AppColors.cyan,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: _glowAnimation.value * 0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título "LEVEL UP!"
                  Text(
                    'LEVEL UP!',
                    style: GoogleFonts.orbitron(
                      color: AppColors.cyan,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(
                          color: AppColors.cyan.withValues(alpha: _glowAnimation.value),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Ícone de nível com animação
                  Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.cyan.withValues(alpha: _glowAnimation.value * 0.8),
                            AppColors.cyan.withValues(alpha: _glowAnimation.value * 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Transform.rotate(
                          angle: -_rotationAnimation.value,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'LEVEL',
                                style: GoogleFonts.shareTechMono(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  letterSpacing: 2,
                                ),
                              ),
                              Text(
                                '${widget.newLevel}',
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Mensagem motivacional
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.1),
                      border: Border.all(
                        color: AppColors.cyan.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _getMotivationalMessage(widget.newLevel),
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '+${widget.xpGained} XP ganhos',
                          style: GoogleFonts.shareTechMono(
                            color: AppColors.cyan,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botão continuar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
          );
        },
      ),
    );
  }
}
