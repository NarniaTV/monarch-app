import 'package:flutter/material.dart';

/// Cores do tema cyberpunk SYSTEM: AWAKEN
class AppColors {
  // Cores principais
  static const Color black = Color(0xFF000000);
  static const Color cyan = Color(0xFF00FFFF);
  static const Color magenta = Color(0xFFFF00FF); // Substitui amarelo por magenta neon

  // Cores secundárias
  static const Color red = Color(0xFFFF0000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkGray = Color(0xFF1A1A1A);
  static const Color mediumGray = Color(0xFF333333);
  static const Color lightGray = Color(0xFF666666);

  // Cores de acento
  static const Color cyanAccent = Color(0xFF00CCCC);
  static const Color magentaAccent = Color(0xFFFF00CC); // Acento magenta
  static const Color redAccent = Color(0xFFFF3333);

  // Cores de fundo
  static const Color background = black;
  static const Color surface = darkGray;
  static const Color surfaceVariant = mediumGray;

  // Cores de texto
  static const Color textPrimary = white;
  static const Color textSecondary = lightGray;
  static const Color textAccent = cyan;
  static const Color textWarning = magenta; // Era yellow
  static const Color textError = red;

  // Cores de borda
  static const Color border = cyan;
  static const Color borderAccent = magenta; // Era yellow

  // Cores de progresso
  static const Color progressBackground = mediumGray;
  static const Color progressFill = cyan;
  static const Color progressFillAccent = magenta; // Era yellow

  // Cores de sombra/shadow
  static const Color shadowGlow = cyan;
  static const Color shadowGlowAccent = magenta; // Era yellow

  // Gradientes
  static const LinearGradient cyanGradient = LinearGradient(
    colors: [cyan, cyanAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient magentaGradient = LinearGradient(
    colors: [magenta, magentaAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redGradient = LinearGradient(
    colors: [red, redAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Cores para ranks
  static const Color rankS = Color(0xFFFFD700); // Dourado - Objetivos Sagrados
  static const Color rankA = Color(0xFFFF8C00); // Laranja Escuro - Metas
  static const Color rankB = Color(0xFFFF6B35); // Laranja Claro - Metas Secundárias
  static const Color rankC = Color(0xFFFF5252); // Vermelho - Tarefas Importantes
  static const Color rankD = Color(0xFF2196F3); // Azul - Tarefas Médias
  static const Color rankE = Color(0xFF4CAF50); // Verde - Tarefas Simples

  // Cores para stats
  static const Color power = red; // Power stat
  static const Color mind = cyan; // Mind stat
  static const Color spirit = magenta; // Spirit stat (era yellow)
}
