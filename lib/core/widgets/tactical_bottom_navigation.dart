import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

/// Bottom Navigation Bar com design Tactical HUD
class TacticalBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const TacticalBottomNavigation({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: AppColors.cyan.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home,
                label: 'DASHBOARD',
                index: 0,
                route: '/',
              ),
              _buildNavItem(
                context,
                icon: Icons.checklist,
                label: 'TAREFAS',
                index: 1,
                route: '/tasks',
              ),
              _buildNavItem(
                context,
                icon: Icons.flag,
                label: 'OBJETIVOS',
                index: 2,
                route: '/objectives',
              ),
              _buildNavItem(
                context,
                icon: Icons.psychology_alt,
                label: 'SOMBRAS',
                index: 3,
                route: '/shadow-inventory',
              ),
              _buildNavItem(
                context,
                icon: Icons.person,
                label: 'PERFIL',
                index: 4,
                route: '/profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
    required String route,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.cyan : Colors.white54;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            context.go(route);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.cyan.withValues(alpha: 0.1)
                : Colors.transparent,
            border: isSelected
                ? Border.all(
                    color: AppColors.cyan.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 22,
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.shareTechMono(
                    color: color,
                    fontSize: 8,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper para determinar o índice atual baseado na rota
  static int getIndexFromRoute(String? location) {
    if (location == null) return 0;
    
    if (location == '/' || location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/tasks')) return 1;
    if (location.startsWith('/objectives')) return 2;
    if (location.startsWith('/shadow-inventory') || location.startsWith('/trophies')) return 3;
    if (location.startsWith('/profile')) return 4;
    
    return 0; // Default
  }
}
