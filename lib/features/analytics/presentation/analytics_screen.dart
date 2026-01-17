import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/tactical_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/analytics_service.dart';

/// Provider para AnalyticsService
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// Tela de Analytics e Insights
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _selectedDays = 7; // 7, 30, 90 dias
  bool _isLoading = true;
  Map<String, dynamic>? _generalStats;
  List<DailyProgress>? _progressHistory;
  List<StatsTrend>? _statsTrend;
  Map<DateTime, int>? _heatmap;
  Map<String, int>? _streaks;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      final analyticsService = ref.read(analyticsServiceProvider);
      
      final results = await Future.wait([
        analyticsService.getGeneralStats(),
        analyticsService.getProgressHistory(_selectedDays),
        analyticsService.getStatsTrend(_selectedDays),
        analyticsService.getProductivityHeatmap(),
        analyticsService.getStreakHistory(),
      ]);
      
      setState(() {
        _generalStats = results[0] as Map<String, dynamic>;
        _progressHistory = results[1] as List<DailyProgress>;
        _statsTrend = results[2] as List<StatsTrend>;
        _heatmap = results[3] as Map<DateTime, int>;
        _streaks = results[4] as Map<String, int>;
        _isLoading = false;
      });
    } catch (e) {
      print('[ANALYTICS SCREEN] ⚠️ Erro ao carregar analytics: $e');
      setState(() => _isLoading = false);
    }
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
                if (_isLoading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.cyan),
                    ),
                  )
                else
                  Expanded(
                    child: _buildContent(),
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
            Colors.black.withValues(alpha: 0.9),
            Colors.transparent,
          ],
        ),
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
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ANALYTICS',
                  style: GoogleFonts.orbitron(
                    color: AppColors.cyan,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Insights e Progresso',
                  style: GoogleFonts.shareTechMono(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Filtro de dias
          Container(
            decoration: BoxDecoration(
              color: AppColors.darkGray,
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDayButton(7, '7D'),
                _buildDayButton(30, '30D'),
                _buildDayButton(90, '90D'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayButton(int days, String label) {
    final isSelected = _selectedDays == days;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedDays = days);
        _loadAnalytics();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cyan : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.orbitron(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estatísticas Gerais
          if (_generalStats != null) _buildGeneralStats(),
          const SizedBox(height: 24),
          
          // Gráfico de Tarefas Completadas
          if (_progressHistory != null) _buildTasksChart(),
          const SizedBox(height: 24),
          
          // Gráfico de XP
          if (_progressHistory != null) _buildXpChart(),
          const SizedBox(height: 24),
          
          // Gráfico Radar de Stats
          if (_statsTrend != null) _buildStatsRadarChart(),
          const SizedBox(height: 24),
          
          // Heatmap de Produtividade
          if (_heatmap != null) _buildProductivityHeatmap(),
          const SizedBox(height: 24),
          
          // Streaks de Hábitos
          if (_streaks != null && _streaks!.isNotEmpty) _buildStreaksSection(),
        ],
      ),
    );
  }

  Widget _buildGeneralStats() {
    final stats = _generalStats!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkGray.withValues(alpha: 0.8),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ESTATÍSTICAS GERAIS',
            style: GoogleFonts.orbitron(
              color: AppColors.cyan,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Level',
                  '${stats['level'] ?? 0}',
                  AppColors.cyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'XP Total',
                  '${stats['totalXp'] ?? 0}',
                  AppColors.magenta,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Taxa Conclusão',
                  '${(stats['completionRate'] ?? 0.0).toStringAsFixed(1)}%',
                  AppColors.cyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Tarefas Ativas',
                  '${stats['activeTasks'] ?? 0}',
                  AppColors.magenta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.shareTechMono(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
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
    );
  }

  Widget _buildTasksChart() {
    final data = _progressHistory!;
    final maxTasks = data.map((d) => d.tasksCompleted).reduce((a, b) => a > b ? a : b);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkGray.withValues(alpha: 0.8),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TAREFAS COMPLETADAS',
            style: GoogleFonts.orbitron(
              color: AppColors.cyan,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxTasks > 0 ? maxTasks.toDouble() + 2 : 5,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.darkGray,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final date = data[groupIndex].date;
                      return BarTooltipItem(
                        '${rod.toY.toInt()} tarefas\n${DateFormat('dd/MM').format(date)}',
                        GoogleFonts.shareTechMono(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('dd/MM').format(data[value.toInt()].date),
                              style: GoogleFonts.shareTechMono(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.shareTechMono(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.mediumGray.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: AppColors.cyan.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                barGroups: data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final progress = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: progress.tasksCompleted.toDouble(),
                        color: AppColors.cyan,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpChart() {
    final data = _progressHistory!;
    final maxXp = data.map((d) => d.xpGained).reduce((a, b) => a > b ? a : b);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkGray.withValues(alpha: 0.8),
        border: Border.all(color: AppColors.magenta.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'XP GANHO',
            style: GoogleFonts.orbitron(
              color: AppColors.magenta,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxXp > 0 ? maxXp.toDouble() + 10 : 50,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.darkGray,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index >= 0 && index < data.length) {
                          final date = data[index].date;
                          return LineTooltipItem(
                            '${spot.y.toInt()} XP\n${DateFormat('dd/MM').format(date)}',
                            GoogleFonts.shareTechMono(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          );
                        }
                        return null;
                      }).whereType<LineTooltipItem>().toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('dd/MM').format(data[value.toInt()].date),
                              style: GoogleFonts.shareTechMono(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.shareTechMono(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxXp > 0 ? (maxXp / 5).ceil().toDouble() : 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.mediumGray.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: AppColors.magenta.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.xpGained.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: AppColors.magenta,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.magenta.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRadarChart() {
    if (_statsTrend == null || _statsTrend!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final latest = _statsTrend!.last;
    final maxValue = [
      latest.power,
      latest.mind,
      latest.spirit,
    ].reduce((a, b) => a > b ? a : b);
    
    // RadarChart precisa de um único dataset com 3 entradas (uma para cada stat)
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkGray.withValues(alpha: 0.8),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EVOLUÇÃO DE STATS',
            style: GoogleFonts.orbitron(
              color: AppColors.cyan,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    fillColor: AppColors.cyan.withValues(alpha: 0.3),
                    borderColor: AppColors.cyan,
                    borderWidth: 2,
                    dataEntries: [
                      RadarEntry(value: latest.power.toDouble()),
                      RadarEntry(value: latest.mind.toDouble()),
                      RadarEntry(value: latest.spirit.toDouble()),
                    ],
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                tickCount: 5,
                ticksTextStyle: GoogleFonts.shareTechMono(
                  color: Colors.white70,
                  fontSize: 10,
                ),
                radarBorderData: BorderSide(
                  color: AppColors.cyan.withValues(alpha: 0.3),
                  width: 1,
                ),
                titleTextStyle: GoogleFonts.orbitron(
                  color: AppColors.cyan,
                  fontSize: 12,
                ),
                getTitle: (index, angle) {
                  final titles = ['Power', 'Mind', 'Spirit'];
                  return RadarChartTitle(
                    text: titles[index],
                    angle: angle,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatIndicator('Power', latest.power, AppColors.power),
              _buildStatIndicator('Mind', latest.mind, AppColors.mind),
              _buildStatIndicator('Spirit', latest.spirit, AppColors.spirit),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatIndicator(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.shareTechMono(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: GoogleFonts.orbitron(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProductivityHeatmap() {
    if (_heatmap == null || _heatmap!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: _selectedDays - 1));
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkGray.withValues(alpha: 0.8),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HEATMAP DE PRODUTIVIDADE',
            style: GoogleFonts.orbitron(
              color: AppColors.cyan,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(_selectedDays, (index) {
              final date = startDate.add(Duration(days: index));
              final tasksCount = _heatmap![date] ?? 0;
              final intensity = tasksCount > 0 
                  ? (tasksCount / 10).clamp(0.0, 1.0) 
                  : 0.0;
              
              return Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: tasksCount > 0
                      ? AppColors.cyan.withValues(alpha: intensity)
                      : AppColors.mediumGray.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.cyan.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: tasksCount > 0
                      ? Text(
                          tasksCount.toString(),
                          style: GoogleFonts.shareTechMono(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                        )
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Menos',
                style: GoogleFonts.shareTechMono(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(
                        alpha: (index + 1) / 5,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
              Text(
                'Mais',
                style: GoogleFonts.shareTechMono(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreaksSection() {
    if (_streaks == null || _streaks!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkGray.withValues(alpha: 0.8),
        border: Border.all(color: AppColors.magenta.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STREAKS DE HÁBITOS',
            style: GoogleFonts.orbitron(
              color: AppColors.magenta,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          ..._streaks!.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: GoogleFonts.shareTechMono(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.magenta.withValues(alpha: 0.2),
                      border: Border.all(color: AppColors.magenta),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: AppColors.magenta,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.value} dias',
                          style: GoogleFonts.orbitron(
                            color: AppColors.magenta,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
