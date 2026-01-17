import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../../core/widgets/tactical_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../models/objective_model.dart';
import '../../../services/objective_service.dart';

/// Tela de criação de novos Objetivos (S, A, B)
class CreateObjectiveScreen extends ConsumerStatefulWidget {
  final ObjectiveRank? initialRank;
  
  const CreateObjectiveScreen({super.key, this.initialRank});

  @override
  ConsumerState<CreateObjectiveScreen> createState() => _CreateObjectiveScreenState();
}

class _CreateObjectiveScreenState extends ConsumerState<CreateObjectiveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _objectiveService = ObjectiveService();

  late ObjectiveRank _selectedRank;
  bool _isLoading = false;
  
  // Campos para Hábitos (Rank B)
  FrequencyType _selectedFrequency = FrequencyType.daily;
  int _everyXDaysValue = 2;
  final List<int> _selectedWeekDays = []; // 1=Dom, 2=Seg, ..., 7=Sab
  TimeOfDay? _selectedTime; // Horário para hábitos
  StatType _selectedHabitStat = StatType.power; // Atributo do hábito

  @override
  void initState() {
    super.initState();
    _selectedRank = widget.initialRank ?? ObjectiveRank.s;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRankSelector(),
                          const SizedBox(height: 24),
                          _buildInfoCard(),
                          const SizedBox(height: 24),
                          _buildTitleInput(),
                          const SizedBox(height: 20),
                          _buildDescriptionInput(),
                          
                          // Seletor de frequência e atributo (apenas para Hábitos - Rank B)
                          if (_selectedRank == ObjectiveRank.b) ...[
                            const SizedBox(height: 24),
                            _buildStatSelector(),
                            const SizedBox(height: 24),
                            _buildFrequencySelector(),
                            const SizedBox(height: 24),
                            _buildTimeSelector(),
                          ],
                          
                          const SizedBox(height: 32),
                          _buildCreateButton(),
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
                  '// CRIAR_OBJETIVO',
                  style: GoogleFonts.shareTechMono(
                    color: _getRankColor(_selectedRank).withValues(alpha: 0.6),
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NOVO OBJETIVO',
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

  Widget _buildRankSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATEGORIA',
          style: GoogleFonts.shareTechMono(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildRankChip(
              label: 'RANK S',
              subtitle: 'Sagrado',
              rank: ObjectiveRank.s,
              icon: Icons.flag,
            ),
            const SizedBox(width: 12),
            _buildRankChip(
              label: 'RANK A',
              subtitle: 'Meta',
              rank: ObjectiveRank.a,
              icon: Icons.star,
            ),
            const SizedBox(width: 12),
            _buildRankChip(
              label: 'RANK B',
              subtitle: 'Hábito',
              rank: ObjectiveRank.b,
              icon: Icons.repeat,
            ),
          ],
        ),
      ],
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : const Color(0xFF1A1D24),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : Colors.white54,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.orbitron(
                  color: isSelected ? color : Colors.white70,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: GoogleFonts.shareTechMono(
                  color: Colors.white38,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final color = _getRankColor(_selectedRank);
    final info = _getRankInfo(_selectedRank);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              info,
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

  Widget _buildTitleInput() {
    final color = _getRankColor(_selectedRank);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TÍTULO',
          style: GoogleFonts.shareTechMono(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D24),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: TextFormField(
            controller: _titleController,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: _getPlaceholderTitle(_selectedRank),
              hintStyle: GoogleFonts.shareTechMono(
                color: Colors.white38,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Título é obrigatório';
              }
              if (value.trim().length < 3) {
                return 'Título deve ter pelo menos 3 caracteres';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionInput() {
    final color = _getRankColor(_selectedRank);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DESCRIÇÃO (OPCIONAL)',
          style: GoogleFonts.shareTechMono(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D24),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: TextFormField(
            controller: _descriptionController,
            style: GoogleFonts.shareTechMono(
              color: Colors.white,
              fontSize: 14,
            ),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Detalhes sobre seu objetivo...',
              hintStyle: GoogleFonts.shareTechMono(
                color: Colors.white38,
                fontSize: 12,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencySelector() {
    final color = _getRankColor(_selectedRank);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FREQUÊNCIA DO HÁBITO',
          style: GoogleFonts.shareTechMono(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        
        // Opção: Todo dia
        _buildFrequencyOption(
          type: FrequencyType.daily,
          label: 'Todo dia',
          icon: Icons.calendar_today,
        ),
        const SizedBox(height: 12),
        
        // Opção: A cada X dias
        _buildFrequencyOption(
          type: FrequencyType.everyXDays,
          label: 'A cada X dias',
          icon: Icons.repeat,
          child: _selectedFrequency == FrequencyType.everyXDays
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Text(
                        'A cada',
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1D24),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextFormField(
                          initialValue: _everyXDaysValue.toString(),
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (value) {
                            final intValue = int.tryParse(value);
                            if (intValue != null && intValue > 0) {
                              setState(() => _everyXDaysValue = intValue);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'dias',
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),
        
        // Opção: Dias da semana
        _buildFrequencyOption(
          type: FrequencyType.weekly,
          label: 'Dias da semana',
          icon: Icons.date_range,
          child: _selectedFrequency == FrequencyType.weekly
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildWeekDayChip('D', 1),
                      _buildWeekDayChip('S', 2),
                      _buildWeekDayChip('T', 3),
                      _buildWeekDayChip('Q', 4),
                      _buildWeekDayChip('Q', 5),
                      _buildWeekDayChip('S', 6),
                      _buildWeekDayChip('S', 7),
                    ],
                  ),
                )
              : null,
        ),
      ],
    );
  }

  Widget _buildFrequencyOption({
    required FrequencyType type,
    required String label,
    required IconData icon,
    Widget? child,
  }) {
    final isSelected = _selectedFrequency == type;
    final color = _getRankColor(_selectedRank);

    return GestureDetector(
      onTap: () => setState(() => _selectedFrequency = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : const Color(0xFF1A1D24),
          border: Border.all(
            color: isSelected
                ? color
                : color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? color : Colors.white54,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.orbitron(
                    color: isSelected ? color : Colors.white70,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Icon(
                    Icons.check_circle,
                    color: color,
                    size: 20,
                  ),
                ],
              ],
            ),
            if (child != null) child,
          ],
        ),
      ),
    );
  }

  Widget _buildWeekDayChip(String label, int dayValue) {
    final isSelected = _selectedWeekDays.contains(dayValue);
    final color = _getRankColor(_selectedRank);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedWeekDays.remove(dayValue);
          } else {
            _selectedWeekDays.add(dayValue);
          }
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.orbitron(
              color: isSelected ? color : Colors.white54,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatSelector() {
    final color = _getRankColor(_selectedRank);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ATRIBUTO DO HÁBITO',
          style: GoogleFonts.shareTechMono(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            // Power
            Expanded(
              child: _buildStatOption(
                stat: StatType.power,
                label: 'POWER',
                icon: Icons.fitness_center,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            
            // Mind
            Expanded(
              child: _buildStatOption(
                stat: StatType.mind,
                label: 'MIND',
                icon: Icons.psychology,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            
            // Spirit
            Expanded(
              child: _buildStatOption(
                stat: StatType.spirit,
                label: 'SPIRIT',
                icon: Icons.self_improvement,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatOption({
    required StatType stat,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedHabitStat == stat;

    return GestureDetector(
      onTap: () => setState(() => _selectedHabitStat = stat),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withValues(alpha: 0.2) 
              : const Color(0xFF1A1D24),
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
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.orbitron(
                color: isSelected ? color : Colors.white54,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    final color = _getRankColor(_selectedRank);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HORÁRIO',
          style: GoogleFonts.shareTechMono(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        
        GestureDetector(
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: _selectedTime ?? TimeOfDay.now(),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: color,
                      onPrimary: Colors.black,
                      surface: const Color(0xFF0F1115),
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
                    ? color 
                    : color.withValues(alpha: 0.3),
                width: _selectedTime != null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: _selectedTime != null ? color : Colors.white54,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedTime != null
                        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                        : 'Selecionar horário',
                    style: GoogleFonts.orbitron(
                      color: _selectedTime != null ? Colors.white : Colors.white54,
                      fontSize: 14,
                      fontWeight: _selectedTime != null ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    final color = _getRankColor(_selectedRank);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleCreate,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const BeveledRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'CRIAR OBJETIVO',
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    // Validação adicional para hábitos
    if (_selectedRank == ObjectiveRank.b) {
      if (_selectedFrequency == FrequencyType.weekly && _selectedWeekDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selecione pelo menos um dia da semana',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Validação de horário obrigatório para hábitos
      if (_selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selecione um horário para o hábito',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Prepara horário se selecionado
      final timeString = _selectedTime != null
          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
          : null;

      final objective = ObjectiveModel(
        id: const Uuid().v4(),
        userId: user.uid,
        title: _titleController.text.trim(),
        rank: _selectedRank,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        createdAt: DateTime.now(),
        progress: 0,
        time: timeString,
        // Campos de frequência e atributo (apenas para Rank B)
        frequencyType: _selectedRank == ObjectiveRank.b ? _selectedFrequency : null,
        frequencyValue: _selectedRank == ObjectiveRank.b && _selectedFrequency == FrequencyType.everyXDays
            ? _everyXDaysValue
            : null,
        weekDays: _selectedRank == ObjectiveRank.b && _selectedFrequency == FrequencyType.weekly
            ? (List<int>.from(_selectedWeekDays)..sort())
            : null,
        statType: _selectedRank == ObjectiveRank.b ? _selectedHabitStat : null,
      );

      await _objectiveService.createObjective(objective);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Objetivo ${_getRankLabel(_selectedRank)} criado com sucesso!',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao criar objetivo: $e',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  String _getRankLabel(ObjectiveRank rank) {
    switch (rank) {
      case ObjectiveRank.s:
        return 'S';
      case ObjectiveRank.a:
        return 'A';
      case ObjectiveRank.b:
        return 'B';
    }
  }

  String _getRankInfo(ObjectiveRank rank) {
    switch (rank) {
      case ObjectiveRank.s:
        return 'Metas de vida grandes (ex: comprar carro dos sonhos, abrir empresa). Máximo 3 ativas.';
      case ObjectiveRank.a:
        return 'Metas a serem alcançadas com tarefas menores. Você pode ter quantas quiser.';
      case ObjectiveRank.b:
        return 'Hábitos são ações repetidas regularmente (ex: correr, estudar). Sem limite.';
    }
  }

  String _getPlaceholderTitle(ObjectiveRank rank) {
    switch (rank) {
      case ObjectiveRank.s:
        return 'Ex: Comprar carro dos sonhos';
      case ObjectiveRank.a:
        return 'Ex: Conseguir promoção no trabalho';
      case ObjectiveRank.b:
        return 'Ex: Correr 3x por semana';
    }
  }
}
