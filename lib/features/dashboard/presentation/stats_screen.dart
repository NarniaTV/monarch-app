import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/widgets/tactical_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user_profile_model.dart';
import '../../../repositories/user_repository.dart';
import '../../../services/stats_service.dart';

/// Tela de Stats com atributos clicáveis e gráfico triangular
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('STATS', style: GoogleFonts.orbitron()),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.cyan),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          const TacticalBackground(),
          FutureBuilder<UserProfileModel?>(
            future: UserRepository().getUser(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.cyan));
              }
              if (!snapshot.hasData) {
                return Center(child: Text('Perfil não encontrado', style: GoogleFonts.shareTechMono()));
              }

              final profile = snapshot.data!;
              final statsService = StatsService();
              final progress = statsService.calculateLevelProgress(profile.currentXp, profile.level);
              final xpInCurrentLevel = statsService.calculateXpInCurrentLevel(profile.currentXp, profile.level);
              final xpNeededForLevel = statsService.calculateXpNeededForLevel(profile.level);

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildLevelCard(profile.level, xpInCurrentLevel, xpNeededForLevel, progress),
                  const SizedBox(height: 24),
                  Text('// ATRIBUTOS', style: GoogleFonts.shareTechMono(color: AppColors.cyan, fontSize: 11)),
                  const SizedBox(height: 16),
                  _buildStatBar(context, 'POWER', profile.power, Colors.red),
                  const SizedBox(height: 12),
                  _buildStatBar(context, 'MIND', profile.mind, Colors.blue),
                  const SizedBox(height: 12),
                  _buildStatBar(context, 'SPIRIT', profile.spirit, Colors.green),
                  const SizedBox(height: 24),
                  _buildTotalCard(profile.power, profile.mind, profile.spirit),
                  const SizedBox(height: 32),
                  _buildTriangleChart(profile.power, profile.mind, profile.spirit),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(int level, int xpInCurrentLevel, int xpNeededForLevel, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.5), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('LEVEL', style: GoogleFonts.orbitron(color: AppColors.cyan, fontSize: 14, letterSpacing: 2)),
          Text('$level', style: GoogleFonts.orbitron(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('$xpInCurrentLevel / $xpNeededForLevel XP', style: GoogleFonts.shareTechMono(color: AppColors.cyan, fontSize: 11)),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress, backgroundColor: Colors.white10, color: AppColors.cyan),
        ],
      ),
    );
  }

  Widget _buildStatBar(BuildContext context, String label, int value, Color color) {
    return InkWell(
      onTap: () => _showStatInfo(context, label, color),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1115),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: color.withValues(alpha: 0.6), size: 18),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.orbitron(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('$value', style: GoogleFonts.orbitron(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(int power, int mind, int spirit) {
    final total = power + mind + spirit;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip('POWER', power, Colors.red),
              _buildStatChip('MIND', mind, Colors.blue),
              _buildStatChip('SPIRIT', spirit, Colors.green),
            ],
          ),
          const Divider(height: 32, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('TOTAL: ', style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 14)),
              Text('$total', style: GoogleFonts.orbitron(color: AppColors.cyan, fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int value, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.shareTechMono(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('$value', style: GoogleFonts.orbitron(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTriangleChart(int power, int mind, int spirit) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '// GRÁFICO DE ATRIBUTOS',
            style: GoogleFonts.shareTechMono(
              color: AppColors.cyan,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: CustomPaint(
                painter: TriangleStatsPainter(
                  power: power,
                  mind: mind,
                  spirit: spirit,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildChartLegend(),
        ],
      ),
    );
  }

  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('POWER', Colors.red),
        _buildLegendItem('MIND', Colors.blue),
        _buildLegendItem('SPIRIT', Colors.green),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.5),
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.shareTechMono(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showStatInfo(BuildContext context, String statName, Color color) {
    final Map<String, Map<String, String>> statInfo = {
      'POWER': {
        'title': 'POWER (FORÇA)',
        'icon': '💪',
        'description': 'Representa sua força física, resistência e disciplina corporal.',
        'examples': '• Treinar na academia\n• Correr/caminhar\n• Praticar esportes\n• Fazer exercícios físicos\n• Melhorar postura e saúde',
        'benefit': 'Aumenta ao completar tarefas físicas e de saúde.',
      },
      'MIND': {
        'title': 'MIND (MENTE)',
        'icon': '🧠',
        'description': 'Representa sua capacidade intelectual, aprendizado e desenvolvimento mental.',
        'examples': '• Estudar e aprender\n• Ler livros\n• Fazer cursos\n• Programar/criar\n• Resolver problemas complexos',
        'benefit': 'Aumenta ao completar tarefas intelectuais e de aprendizado.',
      },
      'SPIRIT': {
        'title': 'SPIRIT (ESPÍRITO)',
        'icon': '✨',
        'description': 'Representa seu equilíbrio emocional, conexões sociais e bem-estar espiritual.',
        'examples': '• Meditar\n• Passar tempo com família/amigos\n• Hobbies e lazer\n• Autoconhecimento\n• Ajudar outras pessoas',
        'benefit': 'Aumenta ao completar tarefas sociais, emocionais e espirituais.',
      },
    };

    final info = statInfo[statName]!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1115),
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        title: Row(
          children: [
            Text(
              info['icon']!,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                info['title']!,
                style: GoogleFonts.orbitron(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Descrição
              Text(
                info['description']!,
                style: GoogleFonts.shareTechMono(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              
              // Exemplos
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EXEMPLOS DE TAREFAS:',
                      style: GoogleFonts.orbitron(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      info['examples']!,
                      style: GoogleFonts.shareTechMono(
                        color: Colors.white70,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Benefício
              Row(
                children: [
                  Icon(Icons.trending_up, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      info['benefit']!,
                      style: GoogleFonts.shareTechMono(
                        color: AppColors.cyan,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: const BeveledRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
            child: Text(
              'ENTENDI',
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
}

/// CustomPainter para desenhar gráfico triangular de stats
class TriangleStatsPainter extends CustomPainter {
  final int power;
  final int mind;
  final int spirit;

  TriangleStatsPainter({
    required this.power,
    required this.mind,
    required this.spirit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Normaliza os valores (máximo 100 para escala visual)
    final maxValue = max(max(power, mind), max(spirit, 50)).toDouble();
    final powerNorm = (power / maxValue) * radius;
    final mindNorm = (mind / maxValue) * radius;
    final spiritNorm = (spirit / maxValue) * radius;

    // Calcula os 3 vértices do triângulo base (guias)
    final topVertex = Offset(center.dx, center.dy - radius); // POWER (topo)
    final bottomLeftVertex = Offset(
      center.dx - radius * cos(pi / 6),
      center.dy + radius * sin(pi / 6),
    ); // MIND (esquerda embaixo)
    final bottomRightVertex = Offset(
      center.dx + radius * cos(pi / 6),
      center.dy + radius * sin(pi / 6),
    ); // SPIRIT (direita embaixo)

    // Desenha o triângulo base (guia cinza)
    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final guidePath = Path()
      ..moveTo(topVertex.dx, topVertex.dy)
      ..lineTo(bottomLeftVertex.dx, bottomLeftVertex.dy)
      ..lineTo(bottomRightVertex.dx, bottomRightVertex.dy)
      ..close();
    canvas.drawPath(guidePath, guidePaint);

    // Desenha linhas de grade (50%, 75%, 100%)
    for (double scale in [0.25, 0.5, 0.75]) {
      final gridPath = Path()
        ..moveTo(center.dx, center.dy - radius * scale)
        ..lineTo(
          center.dx - radius * scale * cos(pi / 6),
          center.dy + radius * scale * sin(pi / 6),
        )
        ..lineTo(
          center.dx + radius * scale * cos(pi / 6),
          center.dy + radius * scale * sin(pi / 6),
        )
        ..close();
      canvas.drawPath(gridPath, guidePaint);
    }

    // Calcula os pontos dos stats (proporcional aos valores)
    final powerPoint = Offset(center.dx, center.dy - powerNorm);
    final mindPoint = Offset(
      center.dx - mindNorm * cos(pi / 6),
      center.dy + mindNorm * sin(pi / 6),
    );
    final spiritPoint = Offset(
      center.dx + spiritNorm * cos(pi / 6),
      center.dy + spiritNorm * sin(pi / 6),
    );

    // Desenha o triângulo de stats (preenchido)
    final statsFillPaint = Paint()
      ..color = AppColors.cyan.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final statsPath = Path()
      ..moveTo(powerPoint.dx, powerPoint.dy)
      ..lineTo(mindPoint.dx, mindPoint.dy)
      ..lineTo(spiritPoint.dx, spiritPoint.dy)
      ..close();
    canvas.drawPath(statsPath, statsFillPaint);

    // Desenha a borda do triângulo de stats
    final statsStrokePaint = Paint()
      ..color = AppColors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(statsPath, statsStrokePaint);

    // Desenha os pontos de cada stat
    _drawStatPoint(canvas, powerPoint, Colors.red, 'POWER', power);
    _drawStatPoint(canvas, mindPoint, Colors.blue, 'MIND', mind);
    _drawStatPoint(canvas, spiritPoint, Colors.green, 'SPIRIT', spirit);

    // Desenha labels dos vértices
    _drawLabel(canvas, topVertex, 'POWER', Colors.red, Offset(0, -25));
    _drawLabel(canvas, bottomLeftVertex, 'MIND', Colors.blue, Offset(-40, 15));
    _drawLabel(canvas, bottomRightVertex, 'SPIRIT', Colors.green, Offset(10, 15));
  }

  void _drawStatPoint(Canvas canvas, Offset point, Color color, String label, int value) {
    // Círculo externo (brilho)
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 10, glowPaint);

    // Círculo principal
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 6, circlePaint);

    // Borda
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(point, 6, borderPaint);
  }

  void _drawLabel(Canvas canvas, Offset position, String text, Color color, Offset offset) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.orbitron(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx + offset.dx - textPainter.width / 2,
        position.dy + offset.dy,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant TriangleStatsPainter oldDelegate) {
    return oldDelegate.power != power ||
        oldDelegate.mind != mind ||
        oldDelegate.spirit != spirit;
  }
}
