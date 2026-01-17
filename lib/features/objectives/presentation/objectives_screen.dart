import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/widgets/tactical_background.dart';
import '../../../core/widgets/tactical_bottom_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../models/objective_model.dart';
import '../../../repositories/objective_repository.dart';
import '../../../services/objective_service.dart';

/// Tela de gerenciamento de Objetivos (S, A, B)
class ObjectivesScreen extends ConsumerStatefulWidget {
  const ObjectivesScreen({super.key});

  @override
  ConsumerState<ObjectivesScreen> createState() => _ObjectivesScreenState();
}

class _ObjectivesScreenState extends ConsumerState<ObjectivesScreen> {
  final _objectiveRepository = ObjectiveRepository();
  final _objectiveService = ObjectiveService();
  
  ObjectiveRank _selectedRank = ObjectiveRank.s; // Padrão: Rank S

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado')),
      );
    }

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
                _buildHeader(),
                _buildRankFilter(),
                Expanded(
                  child: _buildObjectivesList(user.uid),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(user.uid),
      bottomNavigationBar: TacticalBottomNavigation(currentIndex: currentIndex),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: _getRankColor(_selectedRank).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '// ${_getRankLabel(_selectedRank)}',
                  style: GoogleFonts.shareTechMono(
                    color: _getRankColor(_selectedRank).withValues(alpha: 0.6),
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'OBJETIVOS E METAS',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CATEGORIA:',
            style: GoogleFonts.shareTechMono(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildRankChip(
                label: 'RANK S',
                subtitle: 'Sagrados',
                rank: ObjectiveRank.s,
                icon: Icons.flag,
              ),
              const SizedBox(width: 8),
              _buildRankChip(
                label: 'RANK A',
                subtitle: 'Metas',
                rank: ObjectiveRank.a,
                icon: Icons.star,
              ),
              const SizedBox(width: 8),
            _buildRankChip(
              label: 'RANK B',
              subtitle: 'Hábitos',
              rank: ObjectiveRank.b,
              icon: Icons.flag_outlined,
            ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankChip({
    required String label,
    required String subtitle,
    required ObjectiveRank rank,
    required IconData icon,
  }) {
    final isSelected = _selectedRank == rank;
    final color = _getRankColor(rank);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRank = rank),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : Colors.white54,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.orbitron(
                  color: isSelected ? color : Colors.white70,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: GoogleFonts.shareTechMono(
                  color: Colors.white38,
                  fontSize: 8,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildObjectivesList(String userId) {
    return StreamBuilder<List<ObjectiveModel>>(
      stream: _objectiveRepository.getActiveObjectivesStreamByRank(userId, _selectedRank),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: _getRankColor(_selectedRank)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erro ao carregar objetivos',
              style: GoogleFonts.shareTechMono(color: Colors.red),
            ),
          );
        }

        final objectives = snapshot.data ?? [];

        if (objectives.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: objectives.length,
          itemBuilder: (context, index) {
            return _buildObjectiveCard(objectives[index], userId);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final color = _getRankColor(_selectedRank);
    final label = _getRankLabel(_selectedRank);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedRank == ObjectiveRank.s ? Icons.flag_outlined : Icons.star_outline,
              color: color.withValues(alpha: 0.3),
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'NENHUM OBJETIVO $label',
              style: GoogleFonts.orbitron(
                color: Colors.white54,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _getEmptyMessage(_selectedRank),
              style: GoogleFonts.shareTechMono(
                color: Colors.white38,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObjectiveCard(ObjectiveModel objective, String userId) {
    final color = _getRankColor(objective.rank);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white10,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    border: Border.all(
                      color: color.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    _getRankIcon(objective.rank),
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              objective.title,
                              style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              border: Border.all(
                                color: color.withValues(alpha: 0.5),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'RANK ${objective.rank.name.toUpperCase()}',
                              style: GoogleFonts.shareTechMono(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (objective.description != null && objective.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          objective.description!,
                          style: GoogleFonts.shareTechMono(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showDeleteDialog(objective, userId),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          ),

          // Progresso (S e A) ou Streak (B)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (objective.rank == ObjectiveRank.b) ...[
                  // Streak para hábitos
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: color,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SEQUÊNCIA',
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white54,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${objective.streak} ${objective.streak == 1 ? 'dia' : 'dias'}',
                        style: GoogleFonts.orbitron(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Progresso para metas S e A
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PROGRESSO',
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white54,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${objective.progress}%',
                        style: GoogleFonts.orbitron(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: objective.progress / 100,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color,
                                  color.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.white38,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Criado em ${objective.createdAt.day.toString().padLeft(2, '0')}/${objective.createdAt.month.toString().padLeft(2, '0')}/${objective.createdAt.year}',
                      style: GoogleFonts.shareTechMono(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(String userId) {
    // Apenas Rank S tem limite de 3
    if (_selectedRank != ObjectiveRank.s) {
      return FloatingActionButton.extended(
        onPressed: () => context.push('/objectives/create?rank=${_selectedRank.name}'),
        backgroundColor: _getRankColor(_selectedRank),
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(
          'NOVO OBJETIVO',
          style: GoogleFonts.orbitron(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Para Rank S, verifica limite
    return StreamBuilder<List<ObjectiveModel>>(
      stream: _objectiveRepository.getActiveObjectivesStreamByRank(userId, ObjectiveRank.s),
      builder: (context, snapshot) {
        final canCreate = (snapshot.data?.length ?? 0) < 3;

        return FloatingActionButton.extended(
          onPressed: canCreate
              ? () => context.push('/objectives/create?rank=${ObjectiveRank.s.name}')
              : () => _showLimitDialog(),
          backgroundColor: canCreate ? AppColors.rankS : Colors.grey,
          icon: Icon(
            canCreate ? Icons.add : Icons.block,
            color: Colors.black,
          ),
          label: Text(
            canCreate ? 'NOVO OBJETIVO' : 'LIMITE ATINGIDO',
            style: GoogleFonts.orbitron(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(ObjectiveModel objective, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1115),
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        title: Text(
          'EXCLUIR OBJETIVO',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Tem certeza que deseja excluir "${objective.title}"? Esta ação não pode ser desfeita.',
          style: GoogleFonts.shareTechMono(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCELAR',
              style: GoogleFonts.orbitron(color: AppColors.cyan),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _objectiveService.deleteObjective(userId, objective.id, rank: objective.rank);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Objetivo excluído com sucesso',
                        style: GoogleFonts.shareTechMono(color: Colors.white),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erro ao excluir: $e',
                        style: GoogleFonts.shareTechMono(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              'EXCLUIR',
              style: GoogleFonts.orbitron(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1115),
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        title: Text(
          'LIMITE ATINGIDO',
          style: GoogleFonts.orbitron(
            color: AppColors.rankS,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Você já possui 3 objetivos S ativos. Exclua um objetivo existente para criar um novo.',
          style: GoogleFonts.shareTechMono(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ENTENDI',
              style: GoogleFonts.orbitron(color: AppColors.cyan),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(ObjectiveRank rank) {
    switch (rank) {
      case ObjectiveRank.s:
        return AppColors.rankS;
      case ObjectiveRank.a:
        return AppColors.rankA;
      case ObjectiveRank.b:
        return AppColors.rankB;
    }
  }

  IconData _getRankIcon(ObjectiveRank rank) {
    switch (rank) {
      case ObjectiveRank.s:
        return Icons.flag;
      case ObjectiveRank.a:
        return Icons.star;
      case ObjectiveRank.b:
        return Icons.flag_outlined;
    }
  }

  String _getRankLabel(ObjectiveRank rank) {
    switch (rank) {
      case ObjectiveRank.s:
        return 'METAS_DE_VIDA';
      case ObjectiveRank.a:
        return 'METAS_A_ALCANCAR';
      case ObjectiveRank.b:
        return 'HABITOS';
    }
  }

  String _getEmptyMessage(ObjectiveRank rank) {
    switch (rank) {
      case ObjectiveRank.s:
        return 'Defina suas grandes metas de vida (ex: comprar carro, abrir empresa).';
      case ObjectiveRank.a:
        return 'Crie metas com tarefas menores para alcançá-las.';
      case ObjectiveRank.b:
        return 'Adicione hábitos que você quer praticar regularmente.';
    }
  }
}
