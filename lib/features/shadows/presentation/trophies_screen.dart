import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/tactical_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/trophy_model.dart';
import '../../../services/trophy_service.dart';

/// Provider para o TrophyService
final trophyServiceProvider = Provider((ref) => TrophyService());

/// Provider para stream de troféus
final trophiesStreamProvider = StreamProvider.autoDispose<List<TrophyModel>>((ref) {
  final trophyService = ref.watch(trophyServiceProvider);
  return trophyService.watchTrophies();
});

/// Tela de troféus conquistados
class TrophiesScreen extends ConsumerWidget {
  const TrophiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trophiesAsync = ref.watch(trophiesStreamProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const TacticalBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: trophiesAsync.when(
                    data: (trophies) => _buildContent(context, ref, trophies),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.cyan),
                    ),
                    error: (error, stack) => Center(
                      child: Text(
                        'Erro: $error',
                        style: GoogleFonts.shareTechMono(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.cyan.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.cyan),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MEU LEGADO',
                style: GoogleFonts.orbitron(
                  color: AppColors.cyan,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '// Hall of Victories',
                style: GoogleFonts.shareTechMono(
                  color: AppColors.cyan.withValues(alpha: 0.7),
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<TrophyModel> trophies) {
    if (trophies.isEmpty) {
      return _buildEmptyState();
    }

    final dashboardTrophies = trophies.where((t) => t.displayOnDashboard).toList();
    final otherTrophies = trophies.where((t) => !t.displayOnDashboard).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info sobre seleção de dashboard
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.cyan.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.cyan,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Selecione até 3 troféus para exibir no Dashboard',
                    style: GoogleFonts.shareTechMono(
                      color: AppColors.cyan,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Seção "Exibindo no Dashboard"
          if (dashboardTrophies.isNotEmpty) ...[
            _buildSectionTitle('EXIBINDO NO DASHBOARD', '${dashboardTrophies.length}/3'),
            const SizedBox(height: 12),
            ...dashboardTrophies.map((trophy) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTrophyCard(context, ref, trophy),
                )),
            const SizedBox(height: 24),
          ],

          // Seção "Todos os Troféus"
          _buildSectionTitle('TODOS OS TROFÉUS', trophies.length.toString()),
          const SizedBox(height: 12),
          if (otherTrophies.isEmpty && dashboardTrophies.isEmpty)
            _buildEmptyState()
          else
            ...otherTrophies.map((trophy) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTrophyCard(context, ref, trophy),
                )),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.orbitron(
            color: AppColors.cyan,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        Text(
          count,
          style: GoogleFonts.shareTechMono(
            color: AppColors.cyan.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTrophyCard(
    BuildContext context,
    WidgetRef ref,
    TrophyModel trophy,
  ) {
    final isDisplaying = trophy.displayOnDashboard;
    final goldenColor = const Color(0xFFFFD700); // Dourado

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        border: Border.all(
          color: isDisplaying 
              ? goldenColor
              : goldenColor.withValues(alpha: 0.3),
          width: isDisplaying ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isDisplaying
            ? [
                BoxShadow(
                  color: goldenColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho (ícone + título)
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: goldenColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: goldenColor,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: goldenColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trophy.title,
                      style: GoogleFonts.orbitron(
                        color: goldenColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (trophy.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        trophy.description,
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Estatísticas
          _buildStatRow(
            'Completado em',
            DateFormat('dd/MM/yyyy').format(trophy.completedAt),
            Icons.calendar_today,
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            'Tempo gasto',
            trophy.getTimeMessage(),
            Icons.timer,
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            'Tarefas completadas',
            '${trophy.totalTasksCompleted}',
            Icons.checklist_outlined,
          ),
          if (trophy.statType != null) ...[
            const SizedBox(height: 8),
            _buildStatRow(
              'Stat predominante',
              trophy.statType!.name.toUpperCase(),
              Icons.trending_up,
            ),
          ],

          const SizedBox(height: 16),

          // Checkbox "Exibir no Dashboard"
          InkWell(
            onTap: () => _handleToggleDisplay(context, ref, trophy),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: goldenColor.withValues(alpha: 0.1),
                border: Border.all(
                  color: goldenColor.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    isDisplaying ? Icons.check_box : Icons.check_box_outline_blank,
                    color: goldenColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'EXIBIR NO DASHBOARD',
                    style: GoogleFonts.orbitron(
                      color: goldenColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.cyan.withValues(alpha: 0.7),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.shareTechMono(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.shareTechMono(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: AppColors.cyan.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'SEM TROFÉUS',
            style: GoogleFonts.orbitron(
              color: AppColors.cyan.withValues(alpha: 0.7),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Complete objetivos S para\ndesbloquear troféus',
              style: GoogleFonts.shareTechMono(
                color: Colors.white54,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggleDisplay(
    BuildContext context,
    WidgetRef ref,
    TrophyModel trophy,
  ) async {
    final trophyService = ref.read(trophyServiceProvider);

    try {
      await trophyService.toggleDisplayOnDashboard(
        trophy.id,
        !trophy.displayOnDashboard,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              trophy.displayOnDashboard 
                  ? 'Troféu removido do dashboard' 
                  : 'Troféu adicionado ao dashboard!',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: trophy.displayOnDashboard ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
