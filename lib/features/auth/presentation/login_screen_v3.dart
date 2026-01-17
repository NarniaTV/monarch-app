import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../services/auth_service.dart';

/// Provider para AuthService
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Provider para estado de loading do login
final loginLoadingProvider = StateProvider<bool>((ref) => false);

class LoginScreenV3 extends ConsumerStatefulWidget {
  const LoginScreenV3({super.key});

  @override
  ConsumerState<LoginScreenV3> createState() => _LoginScreenV3State();
}

class _LoginScreenV3State extends ConsumerState<LoginScreenV3> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
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
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // LAYER 1: The Atmosphere (Background)
          _buildBackground(screenSize),

          // LAYER 2: The Tactical Frame (HUD Container)
          Center(
            child: _TacticalFrame(
              child: // LAYER 3: The Interaction UI (Form)
                  _buildForm(isLoading),
            ),
          ),

          // HUD Elements (corners and crosshair)
          _buildHUDElements(screenSize),
        ],
      ),
    );
  }

  Widget _buildBackground(Size screenSize) {
    return Stack(
      children: [
        // Imagem de fundo (placeholder - substituir por asset real)
        Container(
          width: screenSize.width,
          height: screenSize.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0A0A1A), // Azul escuro
                const Color(0xFF1A0A2A), // Roxo escuro
                const Color(0xFF0A0A1A),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: CustomPaint(
            painter: _CyberpunkCityPainter(),
          ),
        ),

        // Blur Effect
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            color: Colors.transparent,
          ),
        ),

        // Overlay escuro
        Container(
          color: Colors.black.withValues(alpha: 0.4),
        ),
      ],
    );
  }

  Widget _buildForm(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email Input
            _buildCyberpunkInput(
              controller: _emailController,
              focusNode: _emailFocusNode,
              label: 'EMAIL ACCESS KEY',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_passwordFocusNode);
              },
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
            const SizedBox(height: 24),

            // Password Input
            _buildCyberpunkInput(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
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
            const SizedBox(height: 32),

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
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // INITIALIZE SYSTEM Button
            _buildSystemButton(
              onPressed: isLoading ? null : _handleLogin,
              isLoading: isLoading,
            ),
            const SizedBox(height: 24),

            // Cadastre-se Button
            TextButton(
              onPressed: () => context.go('/register'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'CADASTRE-SE',
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.7),
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCyberpunkInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: GoogleFonts.shareTechMono(
            color: const Color(0xFF00F0FF),
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        // Input Field
        Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: const Color(0xFF00F0FF),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
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
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemButton({
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF00F0FF),
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
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
      ),
    );
  }

  Widget _buildHUDElements(Size screenSize) {
    return Stack(
      children: [
        // Top-Left HUD
        Positioned(
          top: 40,
          left: 20,
          child: _buildHUDBlock(),
        ),
        // Top-Right HUD
        Positioned(
          top: 40,
          right: 20,
          child: _buildHUDBlock(),
        ),
        // Bottom-Left HUD
        Positioned(
          bottom: 40,
          left: 20,
          child: _buildHUDBlock(),
        ),
        // Bottom-Right Corner Bracket
        Positioned(
          bottom: 40,
          right: 20,
          child: CustomPaint(
            size: const Size(40, 40),
            painter: _CornerBracketPainter(),
          ),
        ),
        // Center Crosshair
        Center(
          child: CustomPaint(
            size: const Size(100, 100),
            painter: _CrosshairPainter(),
          ),
        ),
      ],
    );
  }

  Widget _buildHUDBlock() {
    return Container(
      width: 80,
      height: 60,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(
          color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SYS',
            style: GoogleFonts.shareTechMono(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '---',
            style: GoogleFonts.shareTechMono(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// Painter para cidade cyberpunk (placeholder)
class _CyberpunkCityPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Desenha formas abstratas que representam prédios
    final paint = Paint()
      ..color = const Color(0xFF1A3A5A).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // Prédios abstratos
    for (int i = 0; i < 10; i++) {
      final x = (size.width / 10.0) * i;
      final height = 100.0 + (i % 3) * 50.0;
      canvas.drawRect(
        Rect.fromLTWH(x, size.height - height, 30.0, height),
        paint,
      );
    }

    // Pontos de luz
    final lightPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final x = (size.width / 20.0) * i;
      final y = size.height - 50.0 - (i % 5) * 30.0;
      canvas.drawCircle(Offset(x, y), 2.0, lightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Widget do Frame Tático
class _TacticalFrame extends StatelessWidget {
  final Widget child;

  const _TacticalFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.6),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background do frame
          child,
          // Bordas táticas
          CustomPaint(
            size: Size.infinite,
            painter: _TacticalBorderPainter(),
          ),
        ],
      ),
    );
  }
}

// Painter para bordas táticas complexas
class _TacticalBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final glowPaint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final cornerSize = 20.0;
    final lineLength = 30.0;

    // Top-Left Corner (L-bracket)
    canvas.drawLine(
      Offset(0, cornerSize),
      Offset(0, 0),
      paint,
    );
    canvas.drawLine(
      Offset(0, 0),
      Offset(cornerSize, 0),
      paint,
    );

    // Top-Right Corner
    canvas.drawLine(
      Offset(size.width - cornerSize, 0),
      Offset(size.width, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerSize),
      paint,
    );

    // Bottom-Left Corner
    canvas.drawLine(
      Offset(0, size.height - cornerSize),
      Offset(0, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerSize, size.height),
      paint,
    );

    // Bottom-Right Corner
    canvas.drawLine(
      Offset(size.width - cornerSize, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - cornerSize),
      paint,
    );

    // Top horizontal line with cutout
    final topCutoutWidth = 80.0;
    final topCutoutX = (size.width - topCutoutWidth) / 2;
    canvas.drawLine(
      Offset(cornerSize, 0),
      Offset(topCutoutX, 0),
      paint,
    );
    canvas.drawLine(
      Offset(topCutoutX + topCutoutWidth, 0),
      Offset(size.width - cornerSize, 0),
      paint,
    );

    // Bottom horizontal line with cutout and vertical lines
    final bottomCutoutWidth = 80.0;
    final bottomCutoutX = (size.width - bottomCutoutWidth) / 2;
    canvas.drawLine(
      Offset(cornerSize, size.height),
      Offset(bottomCutoutX, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(bottomCutoutX + bottomCutoutWidth, size.height),
      Offset(size.width - cornerSize, size.height),
      paint,
    );

    // Vertical lines from bottom cutout
    canvas.drawLine(
      Offset(bottomCutoutX, size.height),
      Offset(bottomCutoutX, size.height - 10),
      paint,
    );
    canvas.drawLine(
      Offset(bottomCutoutX + bottomCutoutWidth, size.height),
      Offset(bottomCutoutX + bottomCutoutWidth, size.height - 10),
      paint,
    );

    // Side vertical lines (midpoints)
    final midY = size.height / 2;
    canvas.drawLine(
      Offset(0, midY - lineLength / 2),
      Offset(0, midY + lineLength / 2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, midY - lineLength / 2),
      Offset(size.width, midY + lineLength / 2),
      paint,
    );

    // Glow effect
    canvas.drawLine(
      Offset(0, cornerSize),
      Offset(0, 0),
      glowPaint,
    );
    canvas.drawLine(
      Offset(0, 0),
      Offset(cornerSize, 0),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter para Crosshair central
class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final center = Offset(size.width / 2, size.height / 2);
    final length = 30.0;

    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - length, center.dy),
      Offset(center.dx + length, center.dy),
      paint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - length),
      Offset(center.dx, center.dy + length),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter para Corner Bracket
class _CornerBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final bracketSize = 15.0;

    // L-bracket no canto inferior direito
    canvas.drawLine(
      Offset(size.width - bracketSize, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - bracketSize),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
