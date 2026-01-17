import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../../../services/auth_service.dart';

/// Provider para AuthService
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Provider para estado de loading do login
final loginLoadingProvider = StateProvider<bool>((ref) => false);

class LoginScreenV2 extends ConsumerStatefulWidget {
  const LoginScreenV2({super.key});

  @override
  ConsumerState<LoginScreenV2> createState() => _LoginScreenV2State();
}

class _LoginScreenV2State extends ConsumerState<LoginScreenV2>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isTransitioning = false;

  // Animation Controllers
  late AnimationController _portalPulseController;
  late AnimationController _vortexController;
  late AnimationController _particlesController;
  late AnimationController _transitionController;
  late AnimationController _fogController;
  late AnimationController _energyPulseController;

  // Animations
  late Animation<double> _portalPulseAnimation;
  late Animation<double> _vortexAnimation;
  late Animation<double> _fogAnimation;
  late Animation<double> _energyPulseAnimation;

  @override
  void initState() {
    super.initState();

    // Portal pulse (respiração)
    _portalPulseController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    _portalPulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _portalPulseController, curve: Curves.easeInOut),
    );

    // Vortex rotation
    _vortexController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
    _vortexAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      _vortexController,
    );

    // Energy pulse interno
    _energyPulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _energyPulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _energyPulseController, curve: Curves.easeInOut),
    );

    // Particles
    _particlesController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    // Fog animation
    _fogController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    _fogAnimation = Tween<double>(begin: -0.2, end: 1.2).animate(
      CurvedAnimation(parent: _fogController, curve: Curves.linear),
    );

    // Transition
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Listen to focus changes
    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus || _passwordFocusNode.hasFocus) {
        _particlesController.repeat();
      }
    });
    _passwordFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus || _passwordFocusNode.hasFocus) {
        _particlesController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _portalPulseController.dispose();
    _vortexController.dispose();
    _particlesController.dispose();
    _transitionController.dispose();
    _fogController.dispose();
    _energyPulseController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    setState(() => _isTransitioning = true);
    await _transitionController.forward();

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
        _isTransitioning = false;
      });
      _transitionController.reverse();
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
          // A. Fundo Preto
          Container(color: Colors.black),

          // B. Névoa (Fog)
          AnimatedBuilder(
            animation: _fogAnimation,
            builder: (context, child) {
              return Positioned(
                bottom: -100 + (_fogAnimation.value * MediaQuery.of(context).size.height * 0.3),
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0x1A9D00FF), // 10% opacity
                        const Color(0x0D9D00FF), // 5% opacity
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // C. Portal Central
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _portalPulseAnimation,
                    _vortexAnimation,
                    _energyPulseAnimation,
                  ]),
                  builder: (context, child) {
                    return _HexagonPortal(
                      pulseScale: _portalPulseAnimation.value,
                      vortexRotation: _vortexAnimation.value,
                      energyPulse: _energyPulseAnimation.value,
                      particlesController: _particlesController,
                      isFocused: _emailFocusNode.hasFocus || _passwordFocusNode.hasFocus,
                    );
                  },
                ),
              ],
            ),
          ),

          // D. Inputs e Botão (Foreground)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 320), // Espaço para o portal
                      
                      // Email Input
                      _ChamferedInputField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        label: 'EMAIL',
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
                      const SizedBox(height: 20),

                      // Password Input
                      _ChamferedInputField(
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
                            color: Colors.grey[400],
                            size: 20,
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // AWAKEN Button (menos brilhante)
                      _AwakenButton(
                        onPressed: isLoading || _isTransitioning ? null : _handleLogin,
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: 24),

                      // Link para cadastro
                      TextButton(
                        onPressed: () => context.go('/register'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: Text(
                          'Não tem uma conta? CRIAR CONTA',
                          style: TextStyle(
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.7),
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // E. Transição de Sucesso
          AnimatedBuilder(
            animation: _transitionController,
            builder: (context, child) {
              if (_transitionController.value == 0) return const SizedBox.shrink();
              
              return Container(
                color: Color.lerp(
                  const Color(0xFF9D00FF),
                  Colors.white,
                  _transitionController.value,
                )?.withValues(alpha: _transitionController.value),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Widget do Portal Hexagonal MELHORADO
class _HexagonPortal extends StatelessWidget {
  final double pulseScale;
  final double vortexRotation;
  final double energyPulse;
  final AnimationController particlesController;
  final bool isFocused;

  const _HexagonPortal({
    required this.pulseScale,
    required this.vortexRotation,
    required this.energyPulse,
    required this.particlesController,
    required this.isFocused,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220 * pulseScale,
      height: 220 * pulseScale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow (Bloom) - mais camadas
          CustomPaint(
            size: Size(300 * pulseScale, 300 * pulseScale),
            painter: _PortalGlowPainter(pulseScale: pulseScale),
          ),

          // Anel externo rotacionando
          Transform.rotate(
            angle: -vortexRotation * 0.5,
            child: CustomPaint(
              size: Size(240 * pulseScale, 240 * pulseScale),
              painter: _PortalRingPainter(pulseScale: pulseScale),
            ),
          ),

          // Portal Frame e Energy Field
          CustomPaint(
            size: Size(220 * pulseScale, 220 * pulseScale),
            painter: _HexagonPortalPainter(
              vortexRotation: vortexRotation,
              energyPulse: energyPulse,
              pulseScale: pulseScale,
            ),
          ),

          // Partículas internas
          AnimatedBuilder(
            animation: particlesController,
            builder: (context, child) {
              return _ParticlesWidget(
                controller: particlesController,
                isFocused: isFocused,
              );
            },
          ),
        ],
      ),
    );
  }
}

// Painter para o Glow externo MELHORADO
class _PortalGlowPainter extends CustomPainter {
  final double pulseScale;

  _PortalGlowPainter({required this.pulseScale});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Mais camadas de glow para efeito mais intenso
    for (int i = 8; i > 0; i--) {
      final blurRadius = 25.0 * i;
      final alpha = 0.15 / i;
      final paint = Paint()
        ..color = (i % 2 == 0
                ? const Color(0xFF9D00FF)
                : const Color(0xFF00F0FF))
            .withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);

      canvas.drawCircle(center, radius * (1 - i * 0.08), paint);
    }

    // Glow hexagonal específico
    final hexPath = Path();
    final hexRadius = radius * 0.7;
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final x = center.dx + hexRadius * math.cos(angle);
      final y = center.dy + hexRadius * math.sin(angle);
      if (i == 0) {
        hexPath.moveTo(x, y);
      } else {
        hexPath.lineTo(x, y);
      }
    }
    hexPath.close();

    final hexGlowPaint = Paint()
      ..color = const Color(0xFF9D00FF).withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawPath(hexPath, hexGlowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Painter para anel externo rotacionando
class _PortalRingPainter extends CustomPainter {
  final double pulseScale;

  _PortalRingPainter({required this.pulseScale});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.2;

    // Anel externo com padrão
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final startAngle = angle - 0.2;
      final endAngle = angle + 0.2;

      final paint = Paint()
        ..color = (i % 2 == 0
                ? const Color(0xFF9D00FF)
                : const Color(0xFF00F0FF))
            .withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Painter para o Portal Hexagonal MELHORADO
class _HexagonPortalPainter extends CustomPainter {
  final double vortexRotation;
  final double energyPulse;
  final double pulseScale;

  _HexagonPortalPainter({
    required this.vortexRotation,
    required this.energyPulse,
    required this.pulseScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;

    // Desenhar hexágono
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Energy Field (vórtice interno) - mais elaborado
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(vortexRotation);
    
    // Múltiplas camadas do vórtice
    for (int layer = 0; layer < 3; layer++) {
      final layerRadius = radius * (0.9 - layer * 0.15) * energyPulse;
      final layerPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF9D00FF).withValues(alpha: 0.4 - layer * 0.1),
            const Color(0xFF9D00FF).withValues(alpha: 0.2 - layer * 0.05),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: layerRadius));
      
      canvas.drawCircle(Offset.zero, layerRadius, layerPaint);
    }

    // Padrão espiral interno
    final spiralPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 20; i++) {
      final progress = i / 20.0;
      final spiralRadius = radius * 0.6 * progress;
      final spiralAngle = progress * 4 * math.pi;
      final x = spiralRadius * math.cos(spiralAngle);
      final y = spiralRadius * math.sin(spiralAngle);
      
      if (i > 0) {
        canvas.drawLine(
          Offset(spiralRadius * 0.9 * math.cos(spiralAngle - 0.1), 
                 spiralRadius * 0.9 * math.sin(spiralAngle - 0.1)),
          Offset(x, y),
          spiralPaint,
        );
      }
    }

    canvas.restore();

    // Frame (borda) - mais elaborado
    final framePaint = Paint()
      ..color = const Color(0xFF9D00FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(path, framePaint);

    // Stroke interno ciano com gradiente
    final innerStrokePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF00F0FF),
          const Color(0xFF9D00FF),
          const Color(0xFF00F0FF),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final innerPath = Path();
    final innerRadius = radius * 0.96;
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final x = center.dx + innerRadius * math.cos(angle);
      final y = center.dy + innerRadius * math.sin(angle);
      if (i == 0) {
        innerPath.moveTo(x, y);
      } else {
        innerPath.lineTo(x, y);
      }
    }
    innerPath.close();
    canvas.drawPath(innerPath, innerStrokePaint);

    // Pontos nos vértices
    final vertexPaint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 4, vertexPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Widget de Partículas MELHORADO
class _ParticlesWidget extends StatelessWidget {
  final AnimationController controller;
  final bool isFocused;

  const _ParticlesWidget({
    required this.controller,
    required this.isFocused,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(300, 300),
      painter: _ParticlesPainter(
        animationValue: controller.value,
        isFocused: isFocused,
      ),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final double animationValue;
  final bool isFocused;

  _ParticlesPainter({
    required this.animationValue,
    required this.isFocused,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final particleCount = isFocused ? 30 : 15;

    for (int i = 0; i < particleCount; i++) {
      final progress = (animationValue + (i / particleCount)) % 1.0;
      final angle = (2 * math.pi * i / particleCount) + (progress * 2 * math.pi);
      final distance = 60 + (progress * 120);
      
      final x = center.dx + distance * math.cos(angle);
      final y = center.dy + distance * math.sin(angle) - (progress * 200);

      final opacity = 1.0 - progress;
      final size = 2.0 + (progress * 4.0);
      final paint = Paint()
        ..color = (i % 3 == 0 
            ? Colors.white 
            : i % 3 == 1 
                ? const Color(0xFF00F0FF)
                : const Color(0xFF9D00FF))
            .withValues(alpha: opacity * 0.9);

      canvas.drawCircle(Offset(x, y), size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Input Field com formato chanfrado MELHORADO
class _ChamferedInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Function(String)? onFieldSubmitted;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _ChamferedInputField({
    required this.controller,
    required this.focusNode,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF9D00FF).withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipPath(
        clipper: _ChamferedClipper(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black54,
            border: Border.all(
              color: isFocused
                  ? const Color(0xFF9D00FF)
                  : const Color(0xFF00F0FF).withValues(alpha: 0.3),
              width: isFocused ? 2 : 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
            cursorColor: const Color(0xFF00F0FF),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w500,
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
            validator: validator,
          ),
        ),
      ),
    );
  }
}

// Clipper para formato chanfrado
class _ChamferedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final chamfer = 10.0;

    path.moveTo(chamfer, 0);
    path.lineTo(size.width - chamfer, 0);
    path.lineTo(size.width, chamfer);
    path.lineTo(size.width, size.height - chamfer);
    path.lineTo(size.width - chamfer, size.height);
    path.lineTo(chamfer, size.height);
    path.lineTo(0, size.height - chamfer);
    path.lineTo(0, chamfer);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// Botão AWAKEN (menos brilhante)
class _AwakenButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _AwakenButton({
    required this.onPressed,
    required this.isLoading,
  });

  @override
  State<_AwakenButton> createState() => _AwakenButtonState();
}

class _AwakenButtonState extends State<_AwakenButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              // Glow reduzido
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9D00FF).withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(-3, 0),
                ),
                BoxShadow(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(3, 0),
                ),
              ],
            ),
            child: ClipPath(
              clipper: _ChamferedClipper(),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9D00FF), Color(0xFF00F0FF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onPressed,
                    child: Center(
                      child: widget.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'AWAKEN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
