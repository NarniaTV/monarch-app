import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/tactical_background.dart';
import '../../../core/widgets/tactical_bottom_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/shadow_model.dart';
import '../../../services/shadow_service.dart';

/// Provider para o ShadowService
final shadowServiceProvider = Provider((ref) => ShadowService());

/// Provider para stream de sombras
final shadowsStreamProvider = StreamProvider.autoDispose<List<ShadowModel>>((ref) {
  final shadowService = ref.watch(shadowServiceProvider);
  return shadowService.watchShadows();
});

/// Tela de inventário de sombras
class ShadowInventoryScreen extends ConsumerWidget {
  const ShadowInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shadowsAsync = ref.watch(shadowsStreamProvider);
    final currentLocation = GoRouterState.of(context).uri.toString();
    final currentIndex = TacticalBottomNavigation.getIndexFromRoute(currentLocation);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const TacticalBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: shadowsAsync.when(
                    data: (shadows) => _buildContent(context, ref, shadows),
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
      bottomNavigationBar: TacticalBottomNavigation(currentIndex: currentIndex),
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
                'INVENTÁRIO',
                style: GoogleFonts.orbitron(
                  color: AppColors.cyan,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '// Shadow Arsenal',
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

  Widget _buildContent(BuildContext context, WidgetRef ref, List<ShadowModel> shadows) {
    if (shadows.isEmpty) {
      return _buildEmptyState();
    }

    final equippedShadows = shadows.where((s) => s.isEquipped).toList();
    final availableShadows = shadows.where((s) => !s.isEquipped).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seção "Equipadas"
          _buildSectionTitle('EQUIPADAS', '${equippedShadows.length}/3'),
          const SizedBox(height: 12),
          if (equippedShadows.isEmpty)
            _buildEmptySlot('Nenhuma sombra equipada')
          else
            ...equippedShadows.map((shadow) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildShadowCard(context, ref, shadow, isEquipped: true),
                )),

          const SizedBox(height: 32),

          // Seção "Disponíveis"
          _buildSectionTitle('DISPONÍVEIS', '${availableShadows.length}'),
          const SizedBox(height: 12),
          if (availableShadows.isEmpty)
            _buildEmptySlot('Nenhuma sombra disponível')
          else
            ...availableShadows.map((shadow) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildShadowCard(context, ref, shadow, isEquipped: false),
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
            fontSize: 18,
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

  Widget _buildEmptySlot(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.shareTechMono(
            color: Colors.white38,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildShadowCard(
    BuildContext context,
    WidgetRef ref,
    ShadowModel shadow, {
    required bool isEquipped,
  }) {
    final shadowColor = Color(shadow.getColorValue());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        border: Border.all(
          color: isEquipped 
              ? shadowColor
              : shadowColor.withValues(alpha: 0.3),
          width: isEquipped ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isEquipped
            ? [
                BoxShadow(
                  color: shadowColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho (ícone + nome)
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: shadowColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: shadowColor,
                    width: 2,
                  ),
                ),
                child: Icon(
                  shadow.type == 'objective' ? Icons.emoji_events : Icons.psychology_alt,
                  color: shadowColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shadow.getEpicName(),
                      style: GoogleFonts.orbitron(
                        color: shadowColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shadow.type == 'objective' ? 'Objetivo S' : 'Tarefa ${shadow.taskRank?.name.toUpperCase()}',
                      style: GoogleFonts.shareTechMono(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              _buildStatChip('XP +${shadow.xpBonus}%', shadowColor),
              const SizedBox(width: 8),
              _buildStatChip('EF +${shadow.efficiencyBonus}%', shadowColor),
              if (shadow.statType != null) ...[
                const SizedBox(width: 8),
                _buildStatChip(shadow.statType!.name.toUpperCase(), shadowColor),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Botão Equipar/Desequipar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleToggleEquip(context, ref, shadow, isEquipped),
              style: ElevatedButton.styleFrom(
                backgroundColor: isEquipped 
                    ? Colors.red.withValues(alpha: 0.8)
                    : shadowColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: const BeveledRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
              ),
              child: Text(
                isEquipped ? 'DESEQUIPAR' : 'EQUIPAR',
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.shareTechMono(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: AppColors.cyan.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'INVENTÁRIO VAZIO',
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
              'Complete tarefas Rank C ou superior\npara extrair sombras',
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

  Future<void> _handleToggleEquip(
    BuildContext context,
    WidgetRef ref,
    ShadowModel shadow,
    bool isCurrentlyEquipped,
  ) async {
    final shadowService = ref.read(shadowServiceProvider);

    try {
      if (isCurrentlyEquipped) {
        // Desequipa
        await shadowService.unequipShadow(shadow.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sombra desequipada',
                style: GoogleFonts.shareTechMono(color: Colors.white),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Equipa
        await shadowService.equipShadow(shadow.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sombra equipada!',
                style: GoogleFonts.shareTechMono(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
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
