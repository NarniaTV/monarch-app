import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/widgets/tactical_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/daily_quest_model.dart';
import '../../../services/daily_quest_service.dart';
import '../../../repositories/daily_quest_repository.dart';

/// Provider para stream de daily quests
final dailyQuestsStreamProvider = StreamProvider.autoDispose<List<DailyQuestModel>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value([]);
  }
  return DailyQuestRepository().getDailyQuestsStream(user.uid);
});

/// Tela de Daily Quests com design Militar Futurista
class DailyQuestsScreen extends ConsumerStatefulWidget {
  const DailyQuestsScreen({super.key});

  @override
  ConsumerState<DailyQuestsScreen> createState() => _DailyQuestsScreenState();
}

class _DailyQuestsScreenState extends ConsumerState<DailyQuestsScreen> {
  final _questService = DailyQuestService();

  @override
  void initState() {
    super.initState();
    // Verifica e reseta daily quests ao abrir a tela
    _checkDailyReset();
  }

  Future<void> _checkDailyReset() async {
    try {
      await _questService.checkAndResetDailyQuests();
    } catch (e) {
      debugPrint('Erro ao verificar reset: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final questsAsync = ref.watch(dailyQuestsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const TacticalBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: questsAsync.when(
                    data: (quests) => _buildQuestsList(quests),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.cyan),
                    ),
                    error: (error, stack) => Center(
                      child: Text(
                        'Erro ao carregar quests',
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
      floatingActionButton: _buildFAB(questsAsync),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
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
                'DAILY QUESTS',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '// MISSÕES DIÁRIAS',
                style: GoogleFonts.shareTechMono(
                  color: AppColors.cyan.withValues(alpha: 0.6),
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestsList(List<DailyQuestModel> quests) {
    if (quests.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard(quests),
        const SizedBox(height: 20),
        ...quests.map((quest) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildQuestCard(quest),
        )),
      ],
    );
  }

  Widget _buildInfoCard(List<DailyQuestModel> quests) {
    final completedToday = quests.where((q) => q.isCompleted).length;
    final total = quests.length;
    final allCompleted = completedToday == total && total > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        border: Border.all(
          color: allCompleted 
              ? Colors.green.withValues(alpha: 0.5)
              : AppColors.cyan.withValues(alpha: 0.3),
          width: allCompleted ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            allCompleted ? Icons.check_circle : Icons.calendar_today,
            color: allCompleted ? Colors.green : AppColors.cyan,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allCompleted ? 'TODAS COMPLETADAS HOJE!' : 'PROGRESSO DE HOJE',
                  style: GoogleFonts.orbitron(
                    color: allCompleted ? Colors.green : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completedToday de $total quests completadas',
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
    );
  }

  Widget _buildQuestCard(DailyQuestModel quest) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header com checkbox
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () => _toggleQuest(quest),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: quest.isCompleted
                          ? AppColors.cyan.withValues(alpha: 0.3)
                          : Colors.transparent,
                      border: Border.all(
                        color: AppColors.cyan,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: quest.isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.cyan,
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
                      Row(
                        children: [
                          // Horário (se tiver)
                          if (quest.time != null) ...[
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: AppColors.cyan,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              quest.time!,
                              style: GoogleFonts.shareTechMono(
                                color: AppColors.cyan,
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
                              quest.title,
                              style: GoogleFonts.orbitron(
                                color: quest.isCompleted ? Colors.white54 : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                decoration: quest.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (quest.description != null && quest.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          quest.description!,
                          style: GoogleFonts.shareTechMono(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Botão deletar
                IconButton(
                  onPressed: () => _showDeleteDialog(quest),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
          
          // Footer com streak
          if (quest.streak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white10,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'STREAK: ${quest.streak} ${quest.streak == 1 ? 'dia' : 'dias'}',
                    style: GoogleFonts.shareTechMono(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: AppColors.cyan.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'NENHUMA DAILY QUEST',
            style: GoogleFonts.orbitron(
              color: Colors.white54,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Clique no + para adicionar uma missão diária',
            style: GoogleFonts.shareTechMono(
              color: Colors.white38,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(AsyncValue<List<DailyQuestModel>> questsAsync) {
    final canAdd = questsAsync.maybeWhen(
      data: (quests) => quests.length < 5,
      orElse: () => true,
    );

    return FloatingActionButton(
      onPressed: canAdd ? _showCreateDialog : _showLimitDialog,
      backgroundColor: AppColors.cyan,
      child: const Icon(Icons.add, color: Colors.black, size: 28),
    );
  }

  void _showCreateDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0F1115),
          shape: const BeveledRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          title: Text(
            'NOVA DAILY QUEST',
            style: GoogleFonts.orbitron(
              color: AppColors.cyan,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TÍTULO',
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.cyan,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  style: GoogleFonts.orbitron(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ex: Meditar 10 minutos',
                    hintStyle: GoogleFonts.shareTechMono(color: Colors.white38),
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
                      borderSide: const BorderSide(color: AppColors.cyan, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'HORÁRIO (OPCIONAL)',
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.cyan,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime ?? TimeOfDay.now(),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.cyan,
                              onPrimary: Colors.black,
                              surface: Color(0xFF0F1115),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (time != null) {
                      setDialogState(() => selectedTime = time);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D24),
                      border: Border.all(
                        color: selectedTime != null 
                            ? AppColors.cyan 
                            : AppColors.cyan.withValues(alpha: 0.3),
                        width: selectedTime != null ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: selectedTime != null ? AppColors.cyan : Colors.white54,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          selectedTime != null
                              ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                              : 'Selecionar horário',
                          style: GoogleFonts.orbitron(
                            color: selectedTime != null ? Colors.white : Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
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
                style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 12),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  return;
                }
                
                Navigator.pop(context);
                await _createQuest(
                  titleController.text.trim(),
                  descController.text.trim(),
                  selectedTime,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.black,
                shape: const BeveledRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
              child: Text(
                'CRIAR',
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createQuest(String title, String description, TimeOfDay? time) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final timeString = time != null
          ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
          : null;

      final quests = await _questService.getDailyQuests();
      final order = quests.length;

      final quest = DailyQuestModel.create(
        userId: user.uid,
        title: title,
        description: description.isEmpty ? null : description,
        order: order,
        time: timeString,
      );

      await _questService.createDailyQuest(quest);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Daily Quest criada!',
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
              'Erro: $e',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleQuest(DailyQuestModel quest) async {
    try {
      if (quest.isCompleted) {
        await _questService.uncompleteDailyQuest(quest);
      } else {
        await _questService.completeDailyQuest(quest);
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

  void _showDeleteDialog(DailyQuestModel quest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1115),
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        title: Text(
          'EXCLUIR QUEST',
          style: GoogleFonts.orbitron(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Tem certeza que deseja excluir "${quest.title}"?',
          style: GoogleFonts.shareTechMono(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCELAR',
              style: GoogleFonts.orbitron(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _questService.deleteDailyQuest(quest.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Quest excluída',
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
                        'Erro: $e',
                        style: GoogleFonts.shareTechMono(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: const BeveledRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
            child: Text(
              'EXCLUIR',
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
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Você já tem 5 Daily Quests (máximo permitido). Exclua uma para adicionar nova.',
          style: GoogleFonts.shareTechMono(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan,
              foregroundColor: Colors.black,
              shape: const BeveledRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
            child: Text(
              'ENTENDI',
              style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
