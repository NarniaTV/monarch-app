import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/auth_service.dart';

/// Provider para AuthService
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Provider para estado de loading do login
final loginLoadingProvider = StateProvider<bool>((ref) => false);

/// Tela de Login com Design Tático HUD - Level 2 Detail
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Mostra mensagem de sucesso se acabou de completar onboarding
    _checkOnboardingCompletion();
  }

  Future<void> _checkOnboardingCompletion() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final justCompleted = prefs.getBool('onboarding_just_completed') ?? false;
      
      if (justCompleted) {
        // Remove a flag para não mostrar novamente
        await prefs.remove('onboarding_just_completed');
        
        // Mostra mensagem de sucesso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Usuário cadastrado com sucesso! Faça login para continuar.',
                      style: GoogleFonts.shareTechMono(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF00F0FF),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    ref.read(loginLoadingProvider.notifier).state = true;

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        ref.read(loginLoadingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loginLoadingProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // LAYER 1: Background com Blur e Vignette
          _buildAtmosphere(),

          // LAYER 2: Scanline Overlay
          _buildScanlineOverlay(),

          // LAYER 3: HUD Container com Tactical Frame
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _buildTacticalFrame(isLoading),
            ),
          ),
        ],
      ),
    );
  }

  /// ATMOSPHERE: Background + Blur + Vignette
  Widget _buildAtmosphere() {
    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/images/login_bg.avif',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0A0A1A),
                      const Color(0xFF1A0A2A),
                      const Color(0xFF0A0A1A),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Blur Effect
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(color: Colors.transparent),
          ),
        ),

        // Black Overlay
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.6),
          ),
        ),

        // Vignette (RadialGradient)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black,
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// SCANLINE OVERLAY: CRT Monitor Effect
  Widget _buildScanlineOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: List.generate(
                100,
                (index) => index.isEven
                    ? Colors.black.withValues(alpha: 0.05)
                    : Colors.transparent,
              ),
              stops: List.generate(100, (index) => index / 100),
            ),
          ),
        ),
      ),
    );
  }

  /// TACTICAL FRAME: Container com Corner Brackets e Details
  Widget _buildTacticalFrame(bool isLoading) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Container
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            border: Border.all(
              color: const Color(0xFF00F0FF),
              width: 1.5,
            ),
            borderRadius: BorderRadius.zero,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Micro-Data Header
                _buildMicroDataHeader(),
                const SizedBox(height: 16),

                // Main Title
                Text(
                  '>> SYSTEM_LOGIN',
                  style: GoogleFonts.shareTechMono(
                    color: const Color(0xFF00F0FF),
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 20),

                // Email Input
                _buildCyberpunkInput(
                  controller: _emailController,
                  label: 'EMAIL ACCESS KEY',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email é obrigatório';
                    }
                    if (!value.contains('@')) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password Input
                _buildCyberpunkInput(
                  controller: _passwordController,
                  label: 'PASSWORD',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF00F0FF),
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Senha é obrigatória';
                    }
                    if (value.length < 6) {
                      return 'Senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      border: Border.all(color: Colors.red, width: 1),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.shareTechMono(
                        color: Colors.red,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // INITIALIZE SYSTEM Button
                _buildSystemButton(
                  onPressed: isLoading ? null : _handleLogin,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 16),

                // Cadastre-se Button
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/register'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'CADASTRE-SE',
                      style: GoogleFonts.shareTechMono(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.7),
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Micro-Data Footer
                _buildMicroDataFooter(),
              ],
            ),
          ),
        ),

        // Corner Brackets (L-shapes)
        ..._buildCornerBrackets(),
      ],
    );
  }

  /// MICRO-DATA HEADER
  Widget _buildMicroDataHeader() {
    return Text(
      '// SECURE_LINK_ESTABLISHED :: ID_9940',
      style: GoogleFonts.shareTechMono(
        color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
        fontSize: 9,
        letterSpacing: 0.5,
      ),
    );
  }

  /// MICRO-DATA FOOTER: Status bar com decoração
  Widget _buildMicroDataFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barcode-style decoration
        Row(
          children: List.generate(
            30,
            (index) => Container(
              width: index % 3 == 0 ? 2 : 1,
              height: index % 5 == 0 ? 8 : 6,
              margin: const EdgeInsets.only(right: 2),
              color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Status text
        Text(
          'STATUS: WAITING_INPUT',
          style: GoogleFonts.shareTechMono(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  /// CORNER BRACKETS: L-shapes nos 4 cantos
  List<Widget> _buildCornerBrackets() {
    const bracketSize = 20.0;
    const bracketThickness = 2.5;
    const bracketColor = Color(0xFF00F0FF);

    return [
      // Top Left
      Positioned(
        top: -bracketThickness / 2,
        left: -bracketThickness / 2,
        child: Container(
          width: bracketSize,
          height: bracketSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: bracketColor, width: bracketThickness),
              left: BorderSide(color: bracketColor, width: bracketThickness),
            ),
          ),
        ),
      ),

      // Top Right
      Positioned(
        top: -bracketThickness / 2,
        right: -bracketThickness / 2,
        child: Container(
          width: bracketSize,
          height: bracketSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: bracketColor, width: bracketThickness),
              right: BorderSide(color: bracketColor, width: bracketThickness),
            ),
          ),
        ),
      ),

      // Bottom Left
      Positioned(
        bottom: -bracketThickness / 2,
        left: -bracketThickness / 2,
        child: Container(
          width: bracketSize,
          height: bracketSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: bracketColor, width: bracketThickness),
              left: BorderSide(color: bracketColor, width: bracketThickness),
            ),
          ),
        ),
      ),

      // Bottom Right
      Positioned(
        bottom: -bracketThickness / 2,
        right: -bracketThickness / 2,
        child: Container(
          width: bracketSize,
          height: bracketSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: bracketColor, width: bracketThickness),
              right: BorderSide(color: bracketColor, width: bracketThickness),
            ),
          ),
        ),
      ),
    ];
  }

  /// CYBERPUNK INPUT: Minimalista
  Widget _buildCyberpunkInput({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: GoogleFonts.shareTechMono(
        color: Colors.white,
        fontSize: 14,
      ),
      cursorColor: const Color(0xFF00F0FF),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.shareTechMono(
          color: const Color(0xFF00F0FF),
          fontSize: 12,
          letterSpacing: 1,
        ),
        suffixIcon: suffixIcon,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFF00F0FF),
            width: 1,
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFF00F0FF),
            width: 2,
          ),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
        errorStyle: GoogleFonts.shareTechMono(
          color: Colors.red,
          fontSize: 10,
        ),
      ),
    );
  }

  /// SYSTEM BUTTON: Botão principal
  Widget _buildSystemButton({
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF00F0FF),
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Text(
                    'INITIALIZE SYSTEM',
                    style: GoogleFonts.shareTechMono(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
