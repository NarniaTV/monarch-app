import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/tactical_background.dart';
import '../../../core/widgets/tactical_bottom_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../models/user_profile_model.dart';
import '../../../models/task_model.dart';
import '../../../repositories/user_repository.dart';
import '../../../services/auth_service.dart';
import '../../../services/task_monitoring_service.dart';
import '../../../services/reset_service.dart';
import '../../../services/stats_service.dart';
import '../../../core/widgets/level_up_dialog.dart';
import '../../../features/shadows/presentation/arise_animation_screen.dart';
import '../../../services/shadow_service.dart';
import '../../../services/trophy_service.dart';
import '../../../services/sync_service.dart';
import '../../../services/connectivity_service.dart';
import '../../tasks/data/task_provider.dart';
import 'dart:async';

/// Dashboard principal com design Tactical HUD
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final SyncService _syncService = SyncService();
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isOnline = true;
  Timer? _connectivityTimer;

  @override
  void initState() {
    super.initState();
    // Verifica e gera tarefas de hábitos automaticamente ao abrir o dashboard
    _checkHabitTasks();
    // Verifica conectividade periodicamente
    // Verifica conectividade imediatamente e depois periodicamente
    _checkConnectivity();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkConnectivity();
    });
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }

  /// Verifica estado de conectividade
  Future<void> _checkConnectivity() async {
    try {
      final isOnline = await _connectivityService.isOnline();
      if (mounted && _isOnline != isOnline) {
        setState(() {
          _isOnline = isOnline;
        });
        print('[DASHBOARD] Status de conectividade alterado: ${isOnline ? "ONLINE" : "OFFLINE"}');
      }
    } catch (e) {
      print('[DASHBOARD] Erro ao verificar conectividade: $e');
      // Em caso de erro, assume offline por segurança
      if (mounted && _isOnline) {
        setState(() {
          _isOnline = false;
        });
      }
    }
  }

  /// Verifica hábitos e gera novas tarefas se necessário
  Future<void> _checkHabitTasks() async {
    try {
      final monitoringService = TaskMonitoringService();
      await monitoringService.checkAndGenerateTasksForAllHabits();
    } catch (e) {
      // Falha silenciosa - não afeta a experiência do usuário
      debugPrint('Erro ao verificar hábitos: $e');
    }
  }

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
          // Background tático
          const TacticalBackground(),

          // Conteúdo
          SafeArea(
            bottom: false,
            child: FutureBuilder<UserProfileModel?>(
              future: UserRepository().getUser(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.cyan),
                  );
                }

                if (!snapshot.hasData) {
                  return Center(
                    child: Text(
                      'Erro ao carregar perfil',
                      style: GoogleFonts.shareTechMono(color: Colors.red),
                    ),
                  );
                }

                final profile = snapshot.data!;
                return _buildDashboardContent(user, profile);
              },
            ),
          ),

          // FAB fixo no centro inferior (acima do bottom nav)
          Positioned(
            left: 0,
            right: 0,
            bottom: 80, // Acima do bottom navigation
            child: Center(
              child: _buildFixedFAB(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: TacticalBottomNavigation(currentIndex: currentIndex),
    );
  }

  /// Widget indicador de modo offline
  Widget _buildOfflineIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.2),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.5),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MODO OFFLINE',
                  style: GoogleFonts.orbitron(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tudo funciona normalmente offline',
                  style: GoogleFonts.shareTechMono(
                    color: Colors.orange.withValues(alpha: 0.8),
                    fontSize: 9,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedFAB() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => context.push('/tasks/create'),
        backgroundColor: AppColors.cyan,
        child: const Icon(
          Icons.add,
          color: Colors.black,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildDashboardContent(User user, UserProfileModel profile) {
    return CustomScrollView(
      slivers: [
        // AppBar tático
        _buildTacticalAppBar(profile),

        // Indicador de conectividade (offline)
        if (!_isOnline)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _buildOfflineIndicator(),
            ),
          ),

        // Conteúdo
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Micro-data Header
              _buildMicroDataHeader(),
              const SizedBox(height: 24),

              // Stats resumidos
              _buildStatsOverview(profile),
              const SizedBox(height: 20),

              // Tarefas Ativas
              _buildTasksSection(),
              const SizedBox(height: 20),

              // Sombras Equipadas
              _buildEquippedShadowsSection(),
              const SizedBox(height: 20),

              // Meu Legado (Troféus)
              _buildTrophiesSection(),
              const SizedBox(height: 20),

              // Ações rápidas
              _buildQuickActions(),
              const SizedBox(height: 20),

              // Informações do sistema
              _buildSystemInfo(profile),
              const SizedBox(height: 20),

              // Botão de reset (teste)
              _buildDebugSection(user.uid),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildTacticalAppBar(UserProfileModel profile) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Colors.black.withValues(alpha: 0.8),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.7),
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '// SYSTEM ACCESS GRANTED',
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.cyan.withValues(alpha: 0.6),
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Olá, ${profile.nickname}',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'LEVEL ${profile.level}',
                      style: GoogleFonts.shareTechMono(
                        color: AppColors.cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isOnline ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isOnline ? Colors.green : Colors.orange).withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isOnline ? 'ONLINE' : 'OFFLINE',
                      style: GoogleFonts.shareTechMono(
                        color: _isOnline ? Colors.green : Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMicroDataHeader() {
    return Text(
      '// TACTICAL_HUD_v2.3 :: STATUS_OPERATIONAL',
      style: GoogleFonts.shareTechMono(
        color: AppColors.cyan.withValues(alpha: 0.5),
        fontSize: 9,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildStatsOverview(UserProfileModel profile) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.cyan.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: AppColors.cyan,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'STATUS DO PLAYER',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Stats grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // XP Bar
                _buildXpBar(profile),
                const SizedBox(height: 20),

                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'POWER',
                        profile.power,
                        Colors.red,
                        Icons.fitness_center,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'MIND',
                        profile.mind,
                        Colors.blue,
                        Icons.psychology,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'SPIRIT',
                        profile.spirit,
                        Colors.green,
                        Icons.self_improvement,
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

  Widget _buildXpBar(UserProfileModel profile) {
    // Usa StatsService para calcular XP (mesma fonte que Stats screen)
    final statsService = ref.read(statsServiceProvider);
    final xpInCurrentLevel = statsService.calculateXpInCurrentLevel(profile.currentXp, profile.level);
    final xpNeededForLevel = statsService.calculateXpNeededForLevel(profile.level);
    final progress = xpNeededForLevel > 0 
        ? (xpInCurrentLevel / xpNeededForLevel).clamp(0.0, 1.0) 
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'EXPERIÊNCIA',
              style: GoogleFonts.shareTechMono(
                color: Colors.white70,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
            Text(
              '$xpInCurrentLevel / $xpNeededForLevel XP',
              style: GoogleFonts.shareTechMono(
                color: AppColors.cyan,
                fontSize: 11,
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
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  border: Border.all(
                    color: AppColors.cyan.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.cyan,
                        AppColors.cyan.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(progress * 100).toStringAsFixed(1)}% para Level ${profile.level + 1}',
          style: GoogleFonts.shareTechMono(
            color: Colors.white54,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.shareTechMono(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksSection() {
    final activeTasksAsync = ref.watch(activeTasksProvider);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.cyan.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.task_alt,
                  color: AppColors.cyan,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'TAREFAS DE HOJE',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push('/tasks'),
                  child: Text(
                    'VER TODAS',
                    style: GoogleFonts.orbitron(
                      color: AppColors.cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tarefas
          activeTasksAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.cyan),
              ),
            ),
            error: (error, stack) {
              // Se erro, tenta buscar do Isar local
              print('[DASHBOARD] Erro ao carregar tarefas, tentando dados locais...');
              return FutureBuilder<List<TaskModel>>(
                future: _syncService.getTasksFromLocal(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.cyan),
                      ),
                    );
                  }
                  
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Erro ao carregar tarefas',
                            style: GoogleFonts.shareTechMono(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            error.toString(),
                            style: GoogleFonts.shareTechMono(
                              color: Colors.red.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final localTasks = snapshot.data!;
                  final activeLocalTasks = localTasks.where((t) => !t.isCompleted).toList();
                  
                  // Filtra apenas tarefas de hoje
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  
                  final todayTasks = activeLocalTasks.where((task) {
                    final taskDate = DateTime(
                      task.createdAt.year,
                      task.createdAt.month,
                      task.createdAt.day,
                    );
                    return taskDate.isAtSameMomentAs(today);
                  }).toList();
                  
                  // Ordena: tarefas com horário primeiro (mais cedo → mais tarde), depois sem horário
                  todayTasks.sort((a, b) {
                    if (a.time != null && b.time != null) {
                      return a.time!.compareTo(b.time!);
                    }
                    if (a.time != null && b.time == null) return -1;
                    if (a.time == null && b.time != null) return 1;
                    return 0;
                  });
                  
                  if (todayTasks.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Nenhuma tarefa para hoje',
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  
                  return _buildTasksList(todayTasks);
                },
              );
            },
            data: (tasks) {
              // Filtra apenas tarefas de hoje
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              
              final todayTasks = tasks.where((task) {
                final taskDate = DateTime(
                  task.createdAt.year,
                  task.createdAt.month,
                  task.createdAt.day,
                );
                return taskDate.isAtSameMomentAs(today);
              }).toList();
              
              // Ordena: tarefas com horário primeiro (mais cedo → mais tarde), depois sem horário
              todayTasks.sort((a, b) {
                // Se ambas têm horário, ordena por horário
                if (a.time != null && b.time != null) {
                  return a.time!.compareTo(b.time!);
                }
                // Tarefas com horário vêm primeiro
                if (a.time != null && b.time == null) return -1;
                if (a.time == null && b.time != null) return 1;
                // Se nenhuma tem horário, mantém ordem original
                return 0;
              });
              
              if (todayTasks.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Nenhuma tarefa para hoje',
                    style: GoogleFonts.shareTechMono(color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              // Mostra apenas as 5 primeiras tarefas
              final displayTasks = todayTasks.take(5).toList();

              return Column(
                children: displayTasks.map((task) {
                  return _buildTaskCard(task);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Constrói lista de tarefas (usado no fallback offline)
  Widget _buildTasksList(List<TaskModel> tasks) {
    // Mostra apenas as 5 primeiras tarefas
    final displayTasks = tasks.take(5).toList();

    return Column(
      children: displayTasks.map((task) {
        return _buildTaskCard(task);
      }).toList(),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final rankColor = _getTaskRankColor(task.rank);

    return AnimatedScale(
      scale: task.isCompleted ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: task.isCompleted ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
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
              // Checkbox com animação
              GestureDetector(
                onTap: () => _toggleTaskCompletion(task),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: 20,
                  height: 20,
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: task.isCompleted
                        ? Icon(
                            Icons.check,
                            key: const ValueKey('check'),
                            color: rankColor,
                            size: 14,
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),
                ),
              ),
              const SizedBox(width: 12),

          // Conteúdo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Horário (se existir)
                    if (task.time != null) ...[
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: rankColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.time!,
                        style: GoogleFonts.shareTechMono(
                          color: rankColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 12,
                        color: Colors.white24,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        task.title,
                        style: GoogleFonts.orbitron(
                          color: task.isCompleted ? Colors.white54 : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                                decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildTaskTag(
                      'RANK ${task.rank.name.toUpperCase()}',
                      rankColor,
                    ),
                    const SizedBox(width: 6),
                    _buildTaskTag(
                      task.statType.name.toUpperCase(),
                      _getStatColor(task.statType),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildTaskTag(String label, Color color) {
    return Container(
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
        label,
        style: GoogleFonts.shareTechMono(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getTaskRankColor(TaskRank rank) {
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

  Future<void> _toggleTaskCompletion(TaskModel task) async {
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
                'Tarefa concluída! +${task.xpReward} XP',
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
              'Erro ao atualizar tarefa',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Widget _buildEquippedShadowsSection() {
    final shadowService = ShadowService();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder(
      stream: shadowService.watchEquippedShadows(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '// SOMBRAS EQUIPADAS',
                    style: GoogleFonts.shareTechMono(
                      color: AppColors.cyan.withValues(alpha: 0.7),
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/shadow-inventory'),
                    child: Text(
                      'VER TODAS',
                      style: GoogleFonts.orbitron(
                        color: AppColors.cyan,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  border: Border.all(
                    color: AppColors.cyan.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Nenhuma sombra equipada',
                    style: GoogleFonts.shareTechMono(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final shadows = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '// SOMBRAS EQUIPADAS',
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.cyan.withValues(alpha: 0.7),
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/shadow-inventory'),
                  child: Text(
                    'VER TODAS',
                    style: GoogleFonts.orbitron(
                      color: AppColors.cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: shadows.length,
                itemBuilder: (context, index) {
                  final shadow = shadows[index];
                  final shadowColor = Color(shadow.getColorValue());
                  return Container(
                    width: 120,
                    margin: EdgeInsets.only(right: index < shadows.length - 1 ? 12 : 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      border: Border.all(color: shadowColor, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          shadow.type == 'objective' ? Icons.emoji_events : Icons.psychology_alt,
                          color: shadowColor,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shadow.name.length > 12 
                              ? '${shadow.name.substring(0, 12)}...'
                              : shadow.name,
                          style: GoogleFonts.orbitron(
                            color: shadowColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '+${shadow.xpBonus}% XP',
                          style: GoogleFonts.shareTechMono(
                            color: Colors.white70,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrophiesSection() {
    final trophyService = TrophyService();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder(
      stream: trophyService.watchDashboardTrophies(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '// MEU LEGADO',
                    style: GoogleFonts.shareTechMono(
                      color: AppColors.cyan.withValues(alpha: 0.7),
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/trophies'),
                    child: Text(
                      'VER TODOS',
                      style: GoogleFonts.orbitron(
                        color: AppColors.cyan,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  border: Border.all(
                    color: AppColors.cyan.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Nenhum troféu selecionado',
                    style: GoogleFonts.shareTechMono(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final trophies = snapshot.data!;
        final goldenColor = const Color(0xFFFFD700);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '// MEU LEGADO',
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.cyan.withValues(alpha: 0.7),
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/trophies'),
                  child: Text(
                    'VER TODOS',
                    style: GoogleFonts.orbitron(
                      color: AppColors.cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: trophies.length,
                itemBuilder: (context, index) {
                  final trophy = trophies[index];
                  return Container(
                    width: 140,
                    margin: EdgeInsets.only(right: index < trophies.length - 1 ? 12 : 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      border: Border.all(color: goldenColor, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: goldenColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: goldenColor,
                          size: 32,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          trophy.title.length > 15 
                              ? '${trophy.title.substring(0, 15)}...'
                              : trophy.title,
                          style: GoogleFonts.orbitron(
                            color: goldenColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          trophy.getTimeMessage(),
                          style: GoogleFonts.shareTechMono(
                            color: Colors.white70,
                            fontSize: 9,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '// AÇÕES RÁPIDAS',
          style: GoogleFonts.shareTechMono(
            color: AppColors.cyan.withValues(alpha: 0.7),
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'OBJETIVOS',
                Icons.flag,
                AppColors.rankS,
                () => context.push('/objectives'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'STATS',
                Icons.bar_chart,
                AppColors.cyan,
                () => context.push('/stats'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'DAILY QUESTS',
                Icons.calendar_today,
                Colors.purple,
                () => context.push('/daily-quests'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'SOMBRAS',
                Icons.psychology_alt,
                const Color(0xFF9D00FF),
                () => context.push('/shadow-inventory'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'TROFÉUS',
                Icons.emoji_events,
                const Color(0xFFFFD700),
                () => context.push('/trophies'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'ADD XP (TEST)',
                Icons.science,
                Colors.orange,
                _showAddXpDialog,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Dialog para adicionar XP (teste)
  void _showAddXpDialog() {
    final xpController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1115),
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        title: Text(
          'ADICIONAR XP (TESTE)',
          style: GoogleFonts.orbitron(
            color: AppColors.cyan,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quantidade de XP:',
              style: GoogleFonts.shareTechMono(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: xpController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 18,
              ),
              decoration: InputDecoration(
                hintText: 'Ex: 100',
                hintStyle: GoogleFonts.shareTechMono(
                  color: Colors.white38,
                ),
                filled: true,
                fillColor: const Color(0xFF1A1D24),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.cyan.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.cyan.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.cyan,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCELAR',
              style: GoogleFonts.orbitron(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final xpStr = xpController.text.trim();
              final xp = int.tryParse(xpStr);
              
              if (xp == null || xp <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Digite um valor válido',
                      style: GoogleFonts.shareTechMono(color: Colors.white),
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _addTestXp(xp);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan,
              foregroundColor: Colors.black,
              shape: const BeveledRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
            child: Text(
              'ADICIONAR',
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

  /// Adiciona XP de teste ao usuário
  Future<void> _addTestXp(int xpToAdd) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Usa StatsService para adicionar XP (com detecção de level up)
      final statsService = ref.read(statsServiceProvider);
      final levelUpInfo = await statsService.addXp(xpToAdd);

      if (mounted) {
        // Mostra SnackBar de XP adicionado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '+$xpToAdd XP adicionado!',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Se houve level up, mostra dialog comemorativo
        if (levelUpInfo != null) {
          // Aguarda um pouco para o SnackBar aparecer primeiro
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            LevelUpDialog.show(context, levelUpInfo.newLevel, levelUpInfo.xpGained);
          }
        }

        // Força rebuild para atualizar a UI
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao adicionar XP: $e',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemInfo(UserProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.2),
          width: 1,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '// INFORMAÇÕES DO SISTEMA',
            style: GoogleFonts.shareTechMono(
              color: AppColors.cyan.withValues(alpha: 0.7),
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('USER_ID', '${profile.userId.substring(0, 12)}...'),
          const SizedBox(height: 8),
          _buildInfoRow('EMAIL', profile.email),
          const SizedBox(height: 8),
          _buildInfoRow(
            'CRIADO_EM',
            '${profile.createdAt.day.toString().padLeft(2, '0')}/${profile.createdAt.month.toString().padLeft(2, '0')}/${profile.createdAt.year}',
          ),
          const SizedBox(height: 8),
          _buildInfoRow('TOTAL_STATS', '${profile.power + profile.mind + profile.spirit}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.shareTechMono(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.shareTechMono(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Removido - Logout agora está na tela de Perfil
  //   // Removido - Logout agora está na tela de Perfil
  // Widget _buildLogoutSection() {
  //   return SizedBox(
  //     width: double.infinity,
  //     child: ElevatedButton.icon(
  //       onPressed: () async {
  //         final authService = ref.read(authServiceProvider);
  //         await authService.signOut();
  //         if (mounted) {
  //           context.go('/login');
  //         }
  //       },
  //       icon: const Icon(Icons.logout),
  //       label: Text(
  //         'DESCONECTAR',
  //         style: GoogleFonts.orbitron(
  //           fontSize: 14,
  //           fontWeight: FontWeight.bold,
  //           letterSpacing: 1,
  //         ),
  //       ),
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: Colors.red.withValues(alpha: 0.2),
  //         foregroundColor: Colors.red,
  //         padding: const EdgeInsets.symmetric(vertical: 16),
  //         side: BorderSide(
  //           color: Colors.red.withValues(alpha: 0.5),
  //           width: 1,
  //         ),
  //         shape: const BeveledRectangleBorder(
  //           borderRadius: BorderRadius.all(Radius.circular(8)),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildDebugSection(String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '// DEBUG (TESTE)',
          style: GoogleFonts.shareTechMono(
            color: Colors.orange.withValues(alpha: 0.7),
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        
        // Botão Reset Onboarding
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({'hasCompletedOnboarding': false});

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Onboarding resetado! Faça logout e login novamente.',
                        style: GoogleFonts.shareTechMono(color: Colors.white),
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erro ao resetar: $e',
                        style: GoogleFonts.shareTechMono(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(
              'RESETAR ONBOARDING',
              style: GoogleFonts.orbitron(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange, width: 1),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: const BeveledRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Botão Reset Completo
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showResetConfirmationDialog,
            icon: const Icon(Icons.restore, size: 18),
            label: Text(
              'RESET COMPLETO DO APP',
              style: GoogleFonts.orbitron(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 1),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: const BeveledRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Mostra dialog de confirmação para reset completo
  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1115),
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'RESET COMPLETO',
                style: GoogleFonts.orbitron(
                  color: Colors.red,
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
              Text(
                'ESTA AÇÃO IRÁ DELETAR TUDO:',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildResetConsequence('Level volta para 1'),
              _buildResetConsequence('XP volta para 0'),
              _buildResetConsequence('Stats (Power, Mind, Spirit) zerados'),
              _buildResetConsequence('Todos os Objetivos deletados'),
              _buildResetConsequence('Todas as Tarefas deletadas'),
              _buildResetConsequence('Todos os Daily Quests deletados'),
              _buildResetConsequence('Penalty Zone resetada'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '⚠️ AÇÃO IRREVERSÍVEL\nApenas para testes!',
                  style: GoogleFonts.shareTechMono(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCELAR',
              style: GoogleFonts.orbitron(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performCompleteReset();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: const BeveledRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
            child: Text(
              'RESETAR TUDO',
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

  /// Widget para mostrar consequência do reset
  Widget _buildResetConsequence(String text) {
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
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Executa reset completo do app
  Future<void> _performCompleteReset() async {
    try {
      // Mostra loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Resetando tudo...',
                  style: GoogleFonts.shareTechMono(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 10),
          ),
        );
      }

      // Executa reset
      final resetService = ResetService();
      await resetService.resetUserCompletely();

      // Mostra sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Reset completo! Tudo foi deletado e resetado.',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Força rebuild da tela
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao resetar: $e',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Provider para AuthService
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Provider para StatsService
final statsServiceProvider = Provider<StatsService>((ref) => StatsService());
