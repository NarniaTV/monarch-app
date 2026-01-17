import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

/// Provider para estado de loading do registro
final registerLoadingProvider = StateProvider<bool>((ref) => false);

/// Tela de Registro com Design Tático HUD
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      setState(() {
        _errorMessage = 'Você deve aceitar os termos para continuar';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    ref.read(registerLoadingProvider.notifier).state = true;

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUpWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: null, // Não usamos mais displayName, apenas nickname
        nickname: _nicknameController.text.trim(),
      );

      if (mounted) {
        // Redireciona para onboarding (usuário fica logado)
        context.go('/onboarding');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        ref.read(registerLoadingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(registerLoadingProvider);

    return PopScope(
      canPop: false, // Impede o pop padrão
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Redireciona para login em vez de fechar o app
          context.go('/login');
        }
      },
      child: Scaffold(
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
              color: const Color(0xFF00F0FF), // Cyan
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

                // Main Title (Headline)
                Text(
                  '>> PLAYER REGISTRATION',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle (System data)
                Text(
                  'Enter biometric data to generate ID.',
                  style: GoogleFonts.shareTechMono(
                    color: const Color(0xFF00F0FF), // Cyan neon
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Nickname Input (OBRIGATÓRIO)
                _buildCyberpunkInput(
                  controller: _nicknameController,
                  label: 'NICKNAME',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nickname é obrigatório';
                    }
                    if (value.length < 3) {
                      return 'Nickname deve ter pelo menos 3 caracteres';
                    }
                    if (value.length > 20) {
                      return 'Nickname deve ter no máximo 20 caracteres';
                    }
                    // Validação: apenas letras, números, underscore e hífen
                    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
                      return 'Nickname inválido (apenas letras, números, _ e -)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Email Input
                _buildCyberpunkInput(
                  controller: _emailController,
                  label: 'EMAIL',
                  icon: Icons.mail_outline,
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
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
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
                const SizedBox(height: 20),

                // Confirm Password Input
                _buildCyberpunkInput(
                  controller: _confirmPasswordController,
                  label: 'CONFIRM PASSWORD',
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF00F0FF),
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirmação de senha é obrigatória';
                    }
                    if (value != _passwordController.text) {
                      return 'As senhas não coincidem';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Hexagonal Checkbox (Terms)
                _buildHexagonalCheckbox(),
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

                // GENERATE LICENSE Button (Purple/Cyan Gradient)
                _buildSystemButton(
                  onPressed: isLoading ? null : _handleRegister,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 16),

                // Back to Login Button
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'ALREADY HAVE AN ACCOUNT? LOGIN',
                      style: GoogleFonts.shareTechMono(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.7),
                        fontSize: 10,
                        letterSpacing: 1,
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
      '// NEW_PLAYER_PROTOCOL :: BIOMETRIC_SCAN',
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
              color: const Color(0xFF9D00FF).withValues(alpha: 0.3), // Shadow Purple
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Status text
        Text(
          'STATUS: AWAITING_LICENSE_GENERATION',
          style: GoogleFonts.shareTechMono(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  /// HEXAGONAL CHECKBOX: Custom checkbox com forma hexagonal
  Widget _buildHexagonalCheckbox() {
    return InkWell(
      onTap: () {
        setState(() => _agreeToTerms = !_agreeToTerms);
      },
      child: Row(
        children: [
          // Hexagon Container
          SizedBox(
            width: 24,
            height: 24,
            child: CustomPaint(
              painter: _HexagonCheckboxPainter(
                isChecked: _agreeToTerms,
                color: _agreeToTerms
                    ? const Color(0xFF9D00FF) // Shadow Purple quando marcado
                    : const Color(0xFF00F0FF).withValues(alpha: 0.3), // Cyan outline
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'I agree to the Terms of Service and Privacy Policy',
              style: GoogleFonts.shareTechMono(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// CORNER BRACKETS: L-shapes nos 4 cantos
  List<Widget> _buildCornerBrackets() {
    const bracketSize = 20.0;
    const bracketThickness = 2.5;
    const bracketColor = Color(0xFF00F0FF); // Cyan

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

  /// CYBERPUNK INPUT: Minimalista com ícone
  Widget _buildCyberpunkInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon with glow
        Icon(
          icon,
          color: const Color(0xFF00F0FF),
          size: 18,
          shadows: [
            Shadow(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.6),
              blurRadius: 8,
            ),
          ],
        ),
        const SizedBox(width: 12),

        // Input Field
        Expanded(
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            validator: validator,
            style: GoogleFonts.shareTechMono(
              color: Colors.white,
              fontSize: 13,
            ),
            cursorColor: const Color(0xFF00F0FF),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: GoogleFonts.shareTechMono(
                color: const Color(0xFF00F0FF),
                fontSize: 11,
                letterSpacing: 0.5,
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
          ),
        ),
      ],
    );
  }

  /// SYSTEM BUTTON: Botão principal com gradiente Purple/Cyan
  Widget _buildSystemButton({
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF9D00FF), // Shadow Purple
            Color(0xFF00F0FF), // Cyan
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9D00FF).withValues(alpha: 0.5),
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
                    'GENERATE LICENSE',
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

/// Custom Painter para Hexagonal Checkbox
class _HexagonCheckboxPainter extends CustomPainter {
  final bool isChecked;
  final Color color;

  _HexagonCheckboxPainter({
    required this.isChecked,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = isChecked ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = _createHexagonPath(size);
    canvas.drawPath(path, paint);

    // Desenha checkmark se marcado
    if (isChecked) {
      final checkPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      final checkPath = Path()
        ..moveTo(size.width * 0.25, size.height * 0.5)
        ..lineTo(size.width * 0.45, size.height * 0.7)
        ..lineTo(size.width * 0.75, size.height * 0.3);

      canvas.drawPath(checkPath, checkPaint);
    }
  }

  Path _createHexagonPath(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;

    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - (math.pi / 6);
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_HexagonCheckboxPainter oldDelegate) {
    return oldDelegate.isChecked != isChecked || oldDelegate.color != color;
  }
}
