import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/widgets/tactical_background.dart';
import '../../../core/widgets/tactical_bottom_navigation.dart';
import '../../../core/widgets/level_up_dialog.dart';
import '../../../features/shadows/presentation/arise_animation_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../models/task_model.dart';
import '../data/task_provider.dart';

/// Tela de listagem e gerenciamento de tarefas
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  TaskRank? _selectedRankFilter; // null = todas as tarefas

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
            child: Column(
              children: [
                _buildHeader(),
                _buildFilterChips(),
                Expanded(
                  child: _buildTasksList(user.uid),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tasks/create'),
        backgroundColor: AppColors.cyan,
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(
          'NOVA TAREFA',
          style: GoogleFonts.orbitron(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
            color: AppColors.cyan.withValues(alpha: 0.3),
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
                  '// GERENCIADOR_DE_TAREFAS',
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.cyan.withValues(alpha: 0.6),
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'TAREFAS',
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

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FILTROS:',
            style: GoogleFonts.shareTechMono(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip(
                label: 'TODAS',
                isSelected: _selectedRankFilter == null,
                color: AppColors.cyan,
                onTap: () => setState(() => _selectedRankFilter = null),
              ),
              _buildFilterChip(
                label: 'RANK C',
                isSelected: _selectedRankFilter == TaskRank.c,
                color: AppColors.rankC,
                onTap: () => setState(() => _selectedRankFilter = TaskRank.c),
              ),
              _buildFilterChip(
                label: 'RANK D',
                isSelected: _selectedRankFilter == TaskRank.d,
                color: AppColors.rankD,
                onTap: () => setState(() => _selectedRankFilter = TaskRank.d),
              ),
              _buildFilterChip(
                label: 'RANK E',
                isSelected: _selectedRankFilter == TaskRank.e,
                color: AppColors.rankE,
                onTap: () => setState(() => _selectedRankFilter = TaskRank.e),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.orbitron(
            color: isSelected ? color : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildTasksList(String userId) {
    final activeTasksAsync = ref.watch(activeTasksProvider);
    final completedTasksAsync = ref.watch(completedTasksProvider);

    return activeTasksAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.cyan),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar tarefas',
                style: GoogleFonts.orbitron(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: GoogleFonts.shareTechMono(
                  color: Colors.red.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
      data: (activeTasks) {
        return completedTasksAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.cyan),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Erro ao carregar tarefas',
              style: GoogleFonts.shareTechMono(color: Colors.red),
            ),
          ),
          data: (completedTasks) {
            // Aplicar filtro
            final filteredActive = _selectedRankFilter == null
                ? activeTasks
                : activeTasks.where((t) => t.rank == _selectedRankFilter).toList();

            final filteredCompleted = _selectedRankFilter == null
                ? completedTasks
                : completedTasks.where((t) => t.rank == _selectedRankFilter).toList();

            if (filteredActive.isEmpty && filteredCompleted.isEmpty) {
              return _buildEmptyState();
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (filteredActive.isNotEmpty) ...[
                  _buildSectionHeader('ATIVAS', filteredActive.length),
                  const SizedBox(height: 12),
                  ...filteredActive.map((task) => _buildTaskCard(task, userId)),
                  const SizedBox(height: 24),
                ],
                if (filteredCompleted.isNotEmpty) ...[
                  _buildSectionHeader('CONCLUÍDAS', filteredCompleted.length),
                  const SizedBox(height: 12),
                  ...filteredCompleted.map((task) => _buildTaskCard(task, userId)),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cyan.withValues(alpha: 0.2),
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: 0.5),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            title,
            style: GoogleFonts.orbitron(
              color: AppColors.cyan,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '($count)',
          style: GoogleFonts.shareTechMono(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    String message = _selectedRankFilter == null
        ? 'Nenhuma tarefa cadastrada'
        : 'Nenhuma tarefa encontrada para este filtro';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_outlined,
              color: AppColors.cyan.withValues(alpha: 0.3),
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              message.toUpperCase(),
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
              'Crie uma nova tarefa para começar.',
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

  Widget _buildTaskCard(TaskModel task, String userId) {
    final rankColor = _getRankColor(task.rank);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        border: Border.all(
          color: rankColor.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: InkWell(
        onTap: () {}, // Pode adicionar navegação para detalhes depois
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              GestureDetector(
                onTap: () => _toggleTaskCompletion(task, userId),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: task.isCompleted
                        ? rankColor.withValues(alpha: 0.3)
                        : Colors.transparent,
                    border: Border.all(
                      color: rankColor,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: task.isCompleted
                      ? Icon(
                          Icons.check,
                          color: rankColor,
                          size: 16,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),

              // Conteúdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: GoogleFonts.orbitron(
                        color: task.isCompleted ? Colors.white54 : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (task.description != null && task.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description!,
                        style: GoogleFonts.shareTechMono(
                          color: task.isCompleted ? Colors.white38 : Colors.white70,
                          fontSize: 11,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildTag(
                          'RANK ${task.rank.name.toUpperCase()}',
                          rankColor,
                        ),
                        _buildTag(
                          task.statType.name.toUpperCase(),
                          _getStatColor(task.statType),
                        ),
                        if (task.xpReward > 0)
                          _buildTag(
                            '+${task.xpReward} XP',
                            Colors.amber,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Botão deletar
              IconButton(
                onPressed: () => _showDeleteDialog(task, userId),
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: GoogleFonts.shareTechMono(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getRankColor(TaskRank rank) {
    switch (rank) {
      case TaskRank.c:
        return AppColors.rankC;
      case TaskRank.d:
        return AppColors.rankD;
      case TaskRank.e:
        return AppColors.rankE;
      default:
        return AppColors.cyan;
    }
  }

  Color _getStatColor(StatType stat) {
    switch (stat) {
      case StatType.power:
        return Colors.red;
      case StatType.mind:
        return Colors.blue;
      case StatType.spirit:
        return Colors.green;
    }
  }

  Future<void> _toggleTaskCompletion(TaskModel task, String userId) async {
    final taskService = ref.read(taskServiceProvider);

    try {
      if (task.isCompleted) {
        await taskService.uncompleteTask(task);
      } else {
        final result = await taskService.completeTask(task);

        if (mounted) {
          // Mostra SnackBar de tarefa concluída
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tarefa concluída! +${task.xpReward} XP, +1 ${task.statType.name.toUpperCase()}',
                style: GoogleFonts.shareTechMono(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Se houve level up, mostra dialog comemorativo
          if (result.levelUpInfo != null) {
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              LevelUpDialog.show(
                context,
                result.levelUpInfo!.newLevel,
                result.levelUpInfo!.xpGained,
              );
            }
          }

          // Se sombra foi extraída, mostra animação ARISE
          if (result.extractedShadow != null) {
            await Future.delayed(const Duration(milliseconds: 1000));
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AriseAnimationScreen(
                    shadow: result.extractedShadow!,
                  ),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao atualizar tarefa: $e',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(TaskModel task, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1115),
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        title: Text(
          'EXCLUIR TAREFA',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Tem certeza que deseja excluir "${task.title}"?',
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
              final taskService = ref.read(taskServiceProvider);
              try {
                await taskService.deleteTask(task.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Tarefa excluída',
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
}
