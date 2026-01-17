import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/tactical_background.dart';
import '../../../../core/utils/constants.dart';
import '../../../../models/objective_model.dart';
import '../data/onboarding_provider.dart';
import '../../../../core/routing/app_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Dados dos objetivos
  final List<TextEditingController> _objectiveTitleControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final List<TextEditingController> _objectiveDescriptionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final List<DateTime?> _objectiveDeadlines = [null, null, null];

  // Mensagem da Penalty Zone
  final TextEditingController _penaltyMessageController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _objectiveTitleControllers) {
      controller.dispose();
    }
    for (var controller in _objectiveDescriptionControllers) {
      controller.dispose();
    }
    _penaltyMessageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleFinish() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final onboardingService = ref.read(onboardingServiceProvider);

      // Valida objetivos
      final objectives = <ObjectiveModel>[];
      for (int i = 0; i < 3; i++) {
        final title = _objectiveTitleControllers[i].text.trim();
        if (title.isEmpty) {
          throw Exception('Objetivo ${i + 1} deve ter um título');
        }

        objectives.add(
          ObjectiveModel.create(
            userId: user.uid,
            title: title,
            rank: ObjectiveRank.s, // Onboarding sempre cria Rank S
            description: _objectiveDescriptionControllers[i].text.trim().isEmpty
                ? null
                : _objectiveDescriptionControllers[i].text.trim(),
            deadline: _objectiveDeadlines[i],
          ),
        );
      }

      // Salva objetivos
      await onboardingService.saveObjectives(objectives: objectives);

      // Salva mensagem da Penalty Zone
      final penaltyMessage = _penaltyMessageController.text.trim();
      if (penaltyMessage.isNotEmpty) {
        await onboardingService.savePenaltyMessage(penaltyMessage: penaltyMessage);
      }

      // Marca onboarding como completo
      await onboardingService.markOnboardingComplete();

      if (mounted) {
        // Salva flag temporária para mostrar mensagem de sucesso no próximo login
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_just_completed', true);
        
        // Faz logout após completar onboarding
        final authService = ref.read(authServiceProvider);
        await authService.signOut();
        
        if (mounted) {
          // Redireciona para login
          context.go('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Tactical Background
          const TacticalBackground(),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Indicador de progresso
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: List.generate(4, (index) {
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(
                            right: index < 3 ? 8 : 0,
                          ),
                          decoration: BoxDecoration(
                            color: index <= _currentPage
                                ? AppColors.cyan
                                : AppColors.mediumGray,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Conteúdo das páginas
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    children: [
                      _buildWelcomePage(),
                      _buildObjectivesPage(),
                      _buildPenaltyMessagePage(),
                      _buildTutorialPage(),
                    ],
                  ),
                ),

                // Botões de navegação
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        TextButton(
                          onPressed: _previousPage,
                          child: const Text('VOLTAR'),
                        )
                      else
                        const SizedBox.shrink(),
                  _buildMilitaryContinueButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 80,
              color: AppColors.cyan,
            ),
            const SizedBox(height: 32),
            Text(
              'O Sistema detectou\nseu potencial.',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppColors.cyan,
                    letterSpacing: 2,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Você despertou.',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.magenta,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Text(
              'Prepare-se para uma jornada de transformação.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObjectivesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título Principal
          Text(
            'SUAS 3 CONDIÇÕES DE VITÓRIA',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Subtítulo com Diretriz
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '// DIRETRIZ PRIMÁRIA\nDefina os alicerces da sua nova realidade. Estes são os objetivos pelos quais você lutará quando a exaustão e o fracasso tentarem te parar.',
              style: GoogleFonts.shareTechMono(
                color: const Color(0xFFB0BEC5),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ...List.generate(3, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: index < 2 ? 24 : 0),
              child: _buildTacticalObjectiveCard(index),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPenaltyMessagePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título Principal
          Text(
            'PROTOCOLO DE FALHA CRÍTICA',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Subtítulo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '// MENSAGEM DE RECUPERAÇÃO\nQuando você falhar e entrar na Penalty Zone, esta mensagem aparecerá para te reerguer. Escolha suas palavras com sabedoria.',
              style: GoogleFonts.shareTechMono(
                color: const Color(0xFFB0BEC5),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          
          // Card Militar
          Card(
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.5),
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
              side: BorderSide(
                color: const Color(0xFFFF5252).withValues(alpha: 0.3), // Vermelho para penalty
                width: 1,
              ),
            ),
            color: const Color(0xFF0F1115),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'MENSAGEM DE EMERGÊNCIA',
                    style: GoogleFonts.orbitron(
                      color: const Color(0xFFFF5252),
                      fontSize: 14,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Input de mensagem
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D24),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFFFF5252).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: TextFormField(
                      controller: _penaltyMessageController,
                      maxLines: 8,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      cursorColor: const Color(0xFFFF5252),
                      decoration: InputDecoration(
                        labelText: 'MENSAGEM',
                        hintText: 'Escreva uma mensagem motivacional...',
                        alignLabelWithHint: true,
                        labelStyle: GoogleFonts.shareTechMono(
                          color: const Color(0xFFFF5252).withValues(alpha: 0.7),
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                        hintStyle: GoogleFonts.shareTechMono(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Exemplos
                  Text(
                    'EXEMPLOS DE MENSAGENS:',
                    style: GoogleFonts.shareTechMono(
                      color: const Color(0xFFB0BEC5),
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMilitaryExampleMessage(
                    'Você prometeu. Você falhou. Agora é hora de se reerguer.',
                  ),
                  const SizedBox(height: 8),
                  _buildMilitaryExampleMessage(
                    'A falha é temporária. A desistência é permanente.',
                  ),
                  const SizedBox(height: 8),
                  _buildMilitaryExampleMessage(
                    'Lembre-se do que você quer. Lembre-se do que você prometeu.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// EXEMPLO DE MENSAGEM: Estilo militar
  Widget _buildMilitaryExampleMessage(String message) {
    return InkWell(
      onTap: () {
        _penaltyMessageController.text = message;
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D24),
          border: Border.all(
            color: const Color(0xFFFF5252).withValues(alpha: 0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              Icons.format_quote,
              size: 16,
              color: const Color(0xFFFF5252).withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.shareTechMono(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTutorialPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título Principal
          Text(
            'MANUAL DE OPERAÇÕES',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Subtítulo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '// SYSTEM: AWAKEN v1.0\nConheça os sistemas principais que governarão sua jornada.',
              style: GoogleFonts.shareTechMono(
                color: const Color(0xFFB0BEC5),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          
          _buildMilitaryTutorialCard(
            icon: Icons.star,
            iconColor: const Color(0xFFFFD700), // Dourado para S rank
            title: 'SISTEMA DE RANKS',
            description:
                'S: Objetivos Sagrados (3 máx)\nA: Metas\nB: Metas Secundárias\nC: Tarefas Importantes (100 XP)\nD: Tarefas Médias (50 XP)\nE: Tarefas Simples (25 XP)',
          ),
          const SizedBox(height: 16),
          _buildMilitaryTutorialCard(
            icon: Icons.trending_up,
            iconColor: const Color(0xFFFF5252), // Vermelho para power
            title: 'ATRIBUTOS DE COMBATE',
            description:
                'Power: Força física e ação\nMind: Intelecto e aprendizado\nSpirit: Emoção e criatividade',
          ),
          const SizedBox(height: 16),
          _buildMilitaryTutorialCard(
            icon: Icons.shield,
            iconColor: const Color(0xFF9D00FF), // Roxo para penalty
            title: 'ZONA DE PENALIDADE',
            description:
                'Se você quebrar uma daily quest, entrará na Penalty Zone. Complete 3 dias seguidos para sair.',
          ),
          const SizedBox(height: 16),
          _buildMilitaryTutorialCard(
            icon: Icons.auto_awesome,
            iconColor: const Color(0xFF2DD4BF), // Cyan para shadows
            title: 'SISTEMA SHADOW',
            description:
                'Complete tarefas Rank A ou objetivos S para extrair sombras. Equipe até 3 para ganhar bônus de XP.',
          ),
        ],
      ),
    );
  }

  /// TUTORIAL CARD: Estilo militar
  Widget _buildMilitaryTutorialCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      shape: BeveledRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(
          color: iconColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      color: const Color(0xFF0F1115),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone com container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            
            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.orbitron(
                      color: iconColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: GoogleFonts.shareTechMono(
                      color: const Color(0xFFB0BEC5),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  /// TACTICAL OBJECTIVE CARD: Estilo Militar Futurista
  Widget _buildTacticalObjectiveCard(int index) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      shape: BeveledRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(
          color: const Color(0xFF2DD4BF).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      color: const Color(0xFF0F1115), // Gunmetal Dark
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'OBJETIVO ${index + 1}',
              style: GoogleFonts.orbitron(
                color: const Color(0xFF2DD4BF),
                fontSize: 14,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            // Title Input
            _buildMilitaryInput(
              controller: _objectiveTitleControllers[index],
              label: 'TÍTULO *',
              hint: 'Ex: Formar em Engenharia',
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),

            // Description Input
            _buildMilitaryInput(
              controller: _objectiveDescriptionControllers[index],
              label: 'DESCRIÇÃO (OPCIONAL)',
              hint: 'Detalhes sobre este objetivo...',
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Deadline Button
            _buildDeadlineButton(index),
          ],
        ),
      ),
    );
  }

  /// INPUT MILITAR: Estilo limpo e legível
  Widget _buildMilitaryInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF2DD4BF).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        textCapitalization: textCapitalization,
        maxLines: maxLines,
        style: GoogleFonts.orbitron(
          color: Colors.white,
          fontSize: 16,
        ),
        cursorColor: const Color(0xFF2DD4BF),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.shareTechMono(
            color: const Color(0xFF2DD4BF).withValues(alpha: 0.7),
            fontSize: 12,
            letterSpacing: 0.5,
          ),
          hintStyle: GoogleFonts.shareTechMono(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  /// BOTÃO DEADLINE: Estilo minimalista
  Widget _buildDeadlineButton(int index) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
        );
        if (date != null) {
          setState(() {
            _objectiveDeadlines[index] = date;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF2DD4BF).withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              color: const Color(0xFF2DD4BF),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _objectiveDeadlines[index] != null
                  ? 'Deadline: ${_objectiveDeadlines[index]!.day}/${_objectiveDeadlines[index]!.month}/${_objectiveDeadlines[index]!.year}'
                  : 'DEFINIR DEADLINE (OPCIONAL)',
              style: GoogleFonts.shareTechMono(
                color: const Color(0xFF2DD4BF),
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// BOTÃO CONTINUAR: Estilo Militar
  Widget _buildMilitaryContinueButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _currentPage == 3
            ? (_isLoading ? null : _handleFinish)
            : _nextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00E5FF), // Ciano
          foregroundColor: Colors.black, // Texto preto
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        child: _currentPage == 3 && _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : Text(
                _currentPage == 3 ? 'ENTRAR NO SISTEMA' : 'CONTINUAR',
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }
}
