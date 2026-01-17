import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user_profile_model.dart';
import '../../../repositories/user_repository.dart';
import '../../../services/penalty_service.dart';

/// Tela da Penalty Zone 2.0 com mensagem personalizada
class PenaltyZoneScreen extends ConsumerStatefulWidget {
  const PenaltyZoneScreen({super.key});

  @override
  ConsumerState<PenaltyZoneScreen> createState() => _PenaltyZoneScreenState();
}

class _PenaltyZoneScreenState extends ConsumerState<PenaltyZoneScreen>
    with SingleTickerProviderStateMixin {
  final _penaltyService = PenaltyService();
  late AnimationController _glitchController;
  late Animation<double> _glitchAnimation;

  @override
  void initState() {
    super.initState();
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    )..repeat(reverse: true);
    
    _glitchAnimation = Tween<double>(begin: 0.0, end: 5.0).animate(_glitchController);
  }

  @override
  void dispose() {
    _glitchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<UserProfileModel?>(
        future: UserRepository().getUser(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          }

          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: Text('Erro ao carregar perfil'));
          }

          return _buildPenaltyContent(profile);
        },
      ),
    );
  }

  Widget _buildPenaltyContent(UserProfileModel profile) {
    return Stack(
      children: [
        // Background vermelho escuro com efeito glitch
        AnimatedBuilder(
          animation: _glitchAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    Colors.red.withValues(alpha: 0.2 + (_glitchAnimation.value / 100)),
                    Colors.black,
                  ],
                ),
              ),
            );
          },
        ),
        
        // Scanlines
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: List.generate(50, (index) {
                  return index.isEven
                      ? Colors.transparent
                      : Colors.red.withValues(alpha: 0.02);
                }),
                stops: List.generate(50, (index) => index / 50),
              ),
            ),
          ),
        ),

        // Conteúdo
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Título glitch
                  AnimatedBuilder(
                    animation: _glitchAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_glitchAnimation.value, 0),
                        child: Text(
                          '⚠ PENALTY ZONE ⚠',
                          style: GoogleFonts.orbitron(
                            color: Colors.red,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            shadows: [
                              Shadow(
                                color: Colors.red.withValues(alpha: 0.8),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '// SISTEMA DETECTOU FALHA',
                    style: GoogleFonts.shareTechMono(
                      color: Colors.red.withValues(alpha: 0.6),
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Mensagem personalizada do usuário
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profile.penaltyMessage ?? 
                          'Você quebrou sua palavra. Você desistiu do seu futuro. É isso que você quer ser?',
                          style: GoogleFonts.shareTechMono(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Info
                  Text(
                    'SEU STREAK FOI QUEBRADO',
                    style: GoogleFonts.orbitron(
                      color: Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Escolha seu destino:',
                    style: GoogleFonts.shareTechMono(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botões
                  Column(
                    children: [
                      // Botão "SE REERGUER"
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () => _handleRise(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: const BeveledRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            elevation: 8,
                            shadowColor: Colors.red.withValues(alpha: 0.5),
                          ),
                          child: Text(
                            'SE REERGUER',
                            style: GoogleFonts.orbitron(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Botão "DESISTIR"
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: OutlinedButton(
                          onPressed: () => _showGiveUpDialog(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white54,
                            side: BorderSide(
                              color: Colors.white24,
                              width: 1,
                            ),
                            shape: const BeveledRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                          ),
                          child: Text(
                            'DESISTIR',
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
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRise() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _penaltyService.enterPenaltyZone(user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Penalty Zone ativada. Complete todas as Daily Quests por 3 dias seguidos para se redimir.',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro: $e',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showGiveUpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1115),
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        title: Text(
          '⚠ CONFIRMAÇÃO FINAL ⚠',
          style: GoogleFonts.orbitron(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DESISTIR SIGNIFICA:',
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildConsequence('Resetar todos os Objetivos S'),
            _buildConsequence('Perder TODO o progresso'),
            _buildConsequence('Level reduzido em 50%'),
            _buildConsequence('Todos os streaks zerados'),
            const SizedBox(height: 16),
            Text(
              'ESTA AÇÃO NÃO PODE SER DESFEITA',
              style: GoogleFonts.shareTechMono(
                color: Colors.red,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'NÃO, CONTINUAR',
              style: GoogleFonts.orbitron(
                color: AppColors.cyan,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleGiveUp();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: const BeveledRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
            child: Text(
              'SIM, DESISTIR',
              style: GoogleFonts.orbitron(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsequence(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.close, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.shareTechMono(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGiveUp() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _penaltyService.giveUp(user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Objetivos resetados. Level reduzido. Você pode recomeçar.',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro: $e',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
