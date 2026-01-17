import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/widgets/tactical_background.dart';
import '../../../core/widgets/tactical_bottom_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user_profile_model.dart';
import '../../../repositories/user_repository.dart';
import '../../../services/auth_service.dart';
import '../../../services/calendar_service.dart';
import '../../tasks/data/task_provider.dart';

/// Tela de perfil do usuário
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nicknameController = TextEditingController();
  final _penaltyMessageController = TextEditingController();
  bool _isEditingNickname = false;
  bool _isEditingPenaltyMessage = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _penaltyMessageController.dispose();
    super.dispose();
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
          const TacticalBackground(),
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

                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: Text('Erro ao carregar perfil'),
                  );
                }

                final profile = snapshot.data!;
                
                // Inicializa controllers com dados do perfil
                if (!_isEditingNickname && _nicknameController.text.isEmpty) {
                  _nicknameController.text = profile.nickname;
                }
                if (!_isEditingPenaltyMessage && _penaltyMessageController.text.isEmpty) {
                  _penaltyMessageController.text = profile.penaltyMessage ?? '';
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 24),
                      _buildProfileInfo(profile),
                      const SizedBox(height: 24),
                      _buildGameStats(profile),
                      const SizedBox(height: 24),
                      _buildSettings(profile),
                      const SizedBox(height: 24),
                      _buildLogoutButton(context),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: TacticalBottomNavigation(currentIndex: currentIndex),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
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
              'PERFIL',
              style: GoogleFonts.orbitron(
                color: AppColors.cyan,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            Text(
              '// User Profile',
              style: GoogleFonts.shareTechMono(
                color: AppColors.cyan.withValues(alpha: 0.7),
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileInfo(UserProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '// INFORMAÇÕES DO PERFIL',
            style: GoogleFonts.shareTechMono(
              color: AppColors.cyan.withValues(alpha: 0.7),
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          
          // Email (somente leitura)
          _buildInfoRow(
            'EMAIL',
            profile.email,
            Icons.email,
            null,
          ),
          const SizedBox(height: 16),
          
          // Nickname (editável)
          _buildEditableRow(
            'NICKNAME',
            _nicknameController,
            Icons.person,
            _isEditingNickname,
            onEdit: () => setState(() => _isEditingNickname = true),
            onSave: () => _saveNickname(profile),
            onCancel: () {
              setState(() => _isEditingNickname = false);
              _nicknameController.text = profile.nickname;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGameStats(UserProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '// ESTATÍSTICAS DO JOGO',
            style: GoogleFonts.shareTechMono(
              color: AppColors.cyan.withValues(alpha: 0.7),
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildStatCard('NÍVEL', '${profile.level}', Icons.stars, AppColors.cyan),
          const SizedBox(height: 12),
          _buildStatCard('XP TOTAL', '${profile.currentXp}', Icons.trending_up, Colors.green),
          const SizedBox(height: 12),
          _buildStatCard('POWER', '${profile.power}', Icons.fitness_center, Colors.red),
          const SizedBox(height: 12),
          _buildStatCard('MIND', '${profile.mind}', Icons.psychology, Colors.blue),
          const SizedBox(height: 12),
          _buildStatCard('SPIRIT', '${profile.spirit}', Icons.self_improvement, Colors.green),
        ],
      ),
    );
  }

  Widget _buildSettings(UserProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '// CONFIGURAÇÕES',
            style: GoogleFonts.shareTechMono(
              color: AppColors.cyan.withValues(alpha: 0.7),
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          
          // Mensagem Penalty Zone (editável)
          _buildEditableRow(
            'MENSAGEM PENALTY ZONE',
            _penaltyMessageController,
            Icons.warning,
            _isEditingPenaltyMessage,
            multiline: true,
            onEdit: () => setState(() => _isEditingPenaltyMessage = true),
            onSave: () => _savePenaltyMessage(profile),
            onCancel: () {
              setState(() => _isEditingPenaltyMessage = false);
              _penaltyMessageController.text = profile.penaltyMessage ?? '';
            },
          ),
          
          const SizedBox(height: 16),
          const Divider(color: AppColors.cyan, height: 1),
          const SizedBox(height: 16),
          
          // FASE 2: Configurações Google Calendar
          _buildGoogleCalendarSettings(),
        ],
      ),
    );
  }

  Widget _buildGoogleCalendarSettings() {
    final calendarService = CalendarService();
    
    return FutureBuilder<bool>(
      future: calendarService.isCalendarEnabled(),
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;
        
        return FutureBuilder<String?>(
          future: calendarService.getCalendarEmail(),
          builder: (context, emailSnapshot) {
            final email = emailSnapshot.data;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppColors.cyan, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'GOOGLE CALENDAR',
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                if (isEnabled && email != null) ...[
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Conectado: $email',
                          style: GoogleFonts.shareTechMono(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _disconnectCalendar(calendarService),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const BeveledRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      child: Text(
                        'DESCONECTAR',
                        style: GoogleFonts.orbitron(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    'Sincronize suas tarefas e hábitos com o Google Calendar',
                    style: GoogleFonts.shareTechMono(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _connectCalendar(calendarService),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan.withValues(alpha: 0.8),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const BeveledRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      child: Text(
                        'CONECTAR GOOGLE CALENDAR',
                        style: GoogleFonts.orbitron(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _connectCalendar(CalendarService calendarService) async {
    print('[CONNECT CALENDAR] Iniciando conexão com Google Calendar...');
    try {
      final success = await calendarService.authenticate();
      print('[CONNECT CALENDAR] Resultado da autenticação: $success');
      
      if (success && mounted) {
        print('[CONNECT CALENDAR] Autenticação bem-sucedida, iniciando sincronização...');
        // Sincroniza tarefas existentes com Google Calendar
        final taskService = ref.read(taskServiceProvider);
        final syncedCount = await taskService.syncAllExistingTasksToCalendar();
        print('[CONNECT CALENDAR] Sincronização concluída: $syncedCount tarefa(s)');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              syncedCount > 0
                  ? 'Google Calendar conectado! $syncedCount tarefa(s) sincronizada(s).'
                  : 'Google Calendar conectado com sucesso!',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() {}); // Atualiza UI
      } else if (mounted) {
        print('[CONNECT CALENDAR] Autenticação falhou');
        // Mostrar diálogo com instruções se falhou
        _showCalendarSetupDialog();
      }
    } catch (e, stackTrace) {
      print('[CONNECT CALENDAR] Erro ao conectar: $e');
      print('[CONNECT CALENDAR] Stack trace: $stackTrace');
      if (mounted) {
        // Verificar se é erro de configuração OAuth
        final errorStr = e.toString();
        if (errorStr.contains('ApiException: 10') || 
            errorStr.contains('DEVELOPER_ERROR') ||
            errorStr.contains('sign_in_failed')) {
          _showCalendarSetupDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erro: $e',
                style: GoogleFonts.shareTechMono(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  void _showCalendarSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          'Configuração OAuth Necessária',
          style: GoogleFonts.orbitron(
            color: AppColors.cyan,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Erro: SHA-1 fingerprint não configurado no Google Cloud Console.',
                style: GoogleFonts.shareTechMono(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'SOLUÇÃO:',
                style: GoogleFonts.orbitron(
                  color: AppColors.cyan,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Obter SHA-1 (terminal):',
                style: GoogleFonts.shareTechMono(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'cd android && keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1',
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.cyan,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '2. No Google Cloud Console:',
                style: GoogleFonts.shareTechMono(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
              Text(
                '   • APIs & Services → Credentials',
                style: GoogleFonts.shareTechMono(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
              Text(
                '   • Criar OAuth Client ID (Android)',
                style: GoogleFonts.shareTechMono(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
              Text(
                '   • Package: com.example.monarch',
                style: GoogleFonts.shareTechMono(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
              Text(
                '   • SHA-1: Cole o valor obtido',
                style: GoogleFonts.shareTechMono(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '3. Aguardar 5-10 minutos e testar novamente',
                style: GoogleFonts.shareTechMono(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.orbitron(
                color: AppColors.cyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnectCalendar(CalendarService calendarService) async {
    try {
      await calendarService.disconnect();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Google Calendar desconectado',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {}); // Atualiza UI
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

  Widget _buildInfoRow(String label, String value, IconData icon, VoidCallback? onTap) {
    return Row(
      children: [
        Icon(icon, color: AppColors.cyan, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.shareTechMono(
                  color: Colors.white54,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableRow(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isEditing, {
    bool multiline = false,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    required VoidCallback onCancel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.cyan, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.shareTechMono(
                      color: Colors.white54,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isEditing)
                    TextField(
                      controller: controller,
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      maxLines: multiline ? 3 : 1,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1A1D24),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.cyan.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.cyan.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppColors.cyan),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1D24),
                          border: Border.all(
                            color: AppColors.cyan.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                controller.text.isEmpty ? 'Clique para editar' : controller.text,
                                style: GoogleFonts.orbitron(
                                  color: controller.text.isEmpty ? Colors.white54 : Colors.white,
                                  fontSize: 14,
                                  fontStyle: controller.text.isEmpty ? FontStyle.italic : FontStyle.normal,
                                ),
                                maxLines: multiline ? 3 : 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.edit,
                              color: AppColors.cyan.withValues(alpha: 0.7),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (isEditing) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onCancel,
                child: Text(
                  'CANCELAR',
                  style: GoogleFonts.orbitron(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  'SALVAR',
                  style: GoogleFonts.orbitron(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  style: GoogleFonts.orbitron(
                    color: color,
                    fontSize: 18,
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

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showLogoutDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const BeveledRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        child: Text(
          'LOGOUT',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Future<void> _saveNickname(UserProfileModel profile) async {
    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nickname não pode estar vazio',
            style: GoogleFonts.shareTechMono(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isEditingNickname = false;
    });

    try {
      final userRepo = UserRepository();
      await userRepo.updateUser(profile.copyWith(nickname: _nicknameController.text.trim()));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Nickname atualizado!',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao atualizar nickname: $e',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isEditingNickname = true);
      }
    }
  }

  Future<void> _savePenaltyMessage(UserProfileModel profile) async {
    setState(() {
      _isEditingPenaltyMessage = false;
    });

    try {
      final userRepo = UserRepository();
      await userRepo.updateUser(
        profile.copyWith(penaltyMessage: _penaltyMessageController.text.trim().isEmpty 
            ? null 
            : _penaltyMessageController.text.trim()),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Mensagem atualizada!',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao atualizar mensagem: $e',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isEditingPenaltyMessage = true);
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1115),
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        title: Text(
          'LOGOUT',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Tem certeza que deseja sair?',
          style: GoogleFonts.shareTechMono(
            color: Colors.white70,
            fontSize: 14,
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
            onPressed: () async {
              Navigator.pop(context);
              final authService = AuthService();
              await authService.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'SAIR',
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
