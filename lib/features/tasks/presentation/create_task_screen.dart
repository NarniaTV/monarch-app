import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/widgets/tactical_background.dart';
import '../../../core/utils/constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/task_model.dart';
import '../../../models/objective_model.dart';
import '../../../repositories/objective_repository.dart';
import '../../../services/sync_service.dart';
import '../data/task_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Tela de criação de tarefas com design Militar Futurista
class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  TaskRank _selectedRank = TaskRank.e; // Padrão: tarefas simples
  StatType _selectedStat = StatType.power; // Padrão: Power
  String? _linkedObjectiveId;
  List<ObjectiveModel> _objectives = [];
  bool _isLoadingObjectives = true;
  
  // Data e hora obrigatórias
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadObjectives();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Carrega objetivos S ativos para poder linkar
  Future<void> _loadObjectives() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final objectiveRepo = ObjectiveRepository();
      final objectives = await objectiveRepo.getActiveObjectives(user.uid);
      setState(() {
        _objectives = objectives;
        _isLoadingObjectives = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingObjectives = false;
      });
    }
  }

  Future<void> _handleCreateTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validação de data e hora obrigatórias
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selecione uma data para a tarefa',
            style: GoogleFonts.shareTechMono(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selecione um horário para a tarefa',
            style: GoogleFonts.shareTechMono(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ref.read(taskLoadingProvider.notifier).state = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Combina data e hora selecionadas
      final taskDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final timeString = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

      final task = TaskModel.create(
        userId: user.uid,
        title: _titleController.text.trim(),
        description: _descriptionController.text.isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        rank: _selectedRank,
        statType: _selectedStat,
        linkedObjectiveId: _linkedObjectiveId,
      ).copyWith(
        id: const Uuid().v4(),
        createdAt: taskDateTime,
        time: timeString,
      );

      final taskService = ref.read(taskServiceProvider);
      
      // Apenas chama o create - Repository salva no Isar em ~10ms e libera a tela
      // Sincronização com Firestore acontece em background
      await taskService.createTask(task);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tarefa criada com sucesso!', // Sempre instantâneo - offline ou online
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: AppColors.cyan,
            duration: const Duration(seconds: 2),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao criar tarefa: $e',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        ref.read(taskLoadingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(taskLoadingProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background tático
          const TacticalBackground(),

          // Conteúdo
          SafeArea(
            child: Column(
              children: [
                // AppBar customizado
                _buildAppBar(),

                // Formulário
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('// DADOS DA TAREFA'),
                          const SizedBox(height: 16),

                          // Título
                          _buildInputField(
                            controller: _titleController,
                            label: 'TÍTULO',
                            hint: 'Ex: Estudar Flutter',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Título é obrigatório';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Descrição
                          _buildInputField(
                            controller: _descriptionController,
                            label: 'DESCRIÇÃO (OPCIONAL)',
                            hint: 'Detalhes da tarefa...',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),

                          _buildSectionTitle('// CLASSIFICAÇÃO'),
                          const SizedBox(height: 16),

                          // Rank
                          _buildRankSelector(),
                          const SizedBox(height: 16),

                          // Stat
                          _buildStatSelector(),
                          const SizedBox(height: 24),

                          _buildSectionTitle('// VINCULAÇÃO (OPCIONAL)'),
                          const SizedBox(height: 16),

                          // Objetivo S linkado
                          _buildObjectiveSelector(),
                          const SizedBox(height: 24),

                          // Seletores de Data e Hora
                          _buildDateTimeSelectors(),
                          const SizedBox(height: 32),

                          // Botão Criar
                          _buildCreateButton(isLoading),
                        ],
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

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
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
          Text(
            'CRIAR NOVA TAREFA',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.shareTechMono(
        color: AppColors.cyan.withValues(alpha: 0.7),
        fontSize: 12,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.orbitron(
            color: AppColors.cyan,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.shareTechMono(
            color: Colors.white,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.shareTechMono(
              color: Colors.white38,
              fontSize: 14,
            ),
            filled: true,
            fillColor: const Color(0xFF1A1D24),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: BorderSide(
                color: AppColors.cyan.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: BorderSide(
                color: AppColors.cyan.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: const BorderSide(
                color: AppColors.cyan,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: const BorderSide(
                color: Colors.red,
              ),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildRankSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RANK DA TAREFA',
          style: GoogleFonts.orbitron(
            color: AppColors.cyan,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TaskRank.values
              .where((rank) => rank != TaskRank.s && rank != TaskRank.a && rank != TaskRank.b) // S, A, B são para objetivos/metas
              .map((rank) => _buildRankChip(rank))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildRankChip(TaskRank rank) {
    final isSelected = _selectedRank == rank;
    final rankColor = _getRankColor(rank);
    final rankLabel = rank.name.toUpperCase();
    final rankDescription = _getRankDescription(rank);

    return InkWell(
      onTap: () => setState(() => _selectedRank = rank),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? rankColor.withValues(alpha: 0.2)
              : const Color(0xFF1A1D24),
          border: Border.all(
            color: isSelected ? rankColor : AppColors.cyan.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(0),
        ),
        child: Column(
          children: [
            Text(
              'RANK $rankLabel',
              style: GoogleFonts.orbitron(
                color: isSelected ? rankColor : Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              rankDescription,
              style: GoogleFonts.shareTechMono(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STAT AFETADO',
          style: GoogleFonts.orbitron(
            color: AppColors.cyan,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: StatType.values.map((stat) => _buildStatChip(stat)).toList(),
        ),
      ],
    );
  }

  Widget _buildStatChip(StatType stat) {
    final isSelected = _selectedStat == stat;
    final statColor = _getStatColor(stat);
    final statLabel = stat.name.toUpperCase();

    return InkWell(
      onTap: () => setState(() => _selectedStat = stat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? statColor.withValues(alpha: 0.2)
              : const Color(0xFF1A1D24),
          border: Border.all(
            color: isSelected ? statColor : AppColors.cyan.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(0),
        ),
        child: Text(
          statLabel,
          style: GoogleFonts.orbitron(
            color: isSelected ? statColor : Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildObjectiveSelector() {
    if (_isLoadingObjectives) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_objectives.isEmpty) {
      return Text(
        'Nenhum objetivo S ativo disponível',
        style: GoogleFonts.shareTechMono(
          color: Colors.white54,
          fontSize: 12,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LINKAR A OBJETIVO S',
          style: GoogleFonts.orbitron(
            color: AppColors.cyan,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D24),
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: 0.3),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _linkedObjectiveId,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1D24),
              style: GoogleFonts.shareTechMono(
                color: Colors.white,
                fontSize: 14,
              ),
              hint: Text(
                'Nenhum (opcional)',
                style: GoogleFonts.shareTechMono(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    'Nenhum',
                    style: GoogleFonts.shareTechMono(color: Colors.white70),
                  ),
                ),
                ..._objectives.map((objective) {
                  return DropdownMenuItem<String?>(
                    value: objective.id,
                    child: Text(
                      objective.title,
                      style: GoogleFonts.shareTechMono(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _linkedObjectiveId = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSelectors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DATA E HORA',
          style: GoogleFonts.orbitron(
            color: AppColors.cyan,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            // Seletor de Data
            Expanded(
              child: _buildDateSelector(),
            ),
            const SizedBox(width: 12),
            // Seletor de Hora
            Expanded(
              child: _buildTimeSelector(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.cyan,
                  onPrimary: Colors.black,
                  surface: Color(0xFF0F1115),
                  onSurface: Colors.white,
                ),
                dialogBackgroundColor: const Color(0xFF0F1115),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D24),
          border: Border.all(
            color: _selectedDate != null 
                ? AppColors.cyan 
                : AppColors.cyan.withValues(alpha: 0.3),
            width: _selectedDate != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: _selectedDate != null ? AppColors.cyan : Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDate != null
                    ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                    : 'Selecionar data',
                style: GoogleFonts.orbitron(
                  color: _selectedDate != null ? Colors.white : Colors.white54,
                  fontSize: 13,
                  fontWeight: _selectedDate != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return GestureDetector(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _selectedTime ?? TimeOfDay.now(),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.cyan,
                  onPrimary: Colors.black,
                  surface: Color(0xFF0F1115),
                  onSurface: Colors.white,
                ),
                dialogBackgroundColor: const Color(0xFF0F1115),
              ),
              child: child!,
            );
          },
        );
        if (time != null) {
          setState(() => _selectedTime = time);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D24),
          border: Border.all(
            color: _selectedTime != null 
                ? AppColors.cyan 
                : AppColors.cyan.withValues(alpha: 0.3),
            width: _selectedTime != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: _selectedTime != null ? AppColors.cyan : Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedTime != null
                    ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                    : 'Selecionar hora',
                style: GoogleFonts.orbitron(
                  color: _selectedTime != null ? Colors.white : Colors.white54,
                  fontSize: 13,
                  fontWeight: _selectedTime != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleCreateTask,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: Colors.black,
          shape: const BeveledRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.black)
            : Text(
                'CRIAR TAREFA',
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }

  Color _getRankColor(TaskRank rank) {
    switch (rank) {
      case TaskRank.s:
        return AppColors.rankS;
      case TaskRank.a:
        return AppColors.rankA;
      case TaskRank.b:
        return AppColors.rankB;
      case TaskRank.c:
        return AppColors.rankC;
      case TaskRank.d:
        return AppColors.rankD;
      case TaskRank.e:
        return AppColors.rankE;
    }
  }

  String _getRankDescription(TaskRank rank) {
    switch (rank) {
      case TaskRank.c:
        return '100 XP • Importante';
      case TaskRank.d:
        return '50 XP • Média';
      case TaskRank.e:
        return '25 XP • Simples';
      default:
        return '';
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
}
