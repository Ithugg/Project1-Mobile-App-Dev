import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_helper.dart';

/// Progress dashboard showing streak heatmap, volume charts, and muscle group distribution.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _workoutCount = 0;
  int _totalMinutes = 0;
  int _streak = 0;
  List<Map<String, dynamic>> _weeklyVolume = [];
  Map<String, int> _muscleDistribution = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db = context.read<DatabaseHelper>();
    final count = await db.getWorkoutCount();
    final minutes = await db.getTotalMinutes();
    final streak = await db.getCurrentStreak();
    final volume = await db.getWeeklyVolume(weeks: 8);
    final muscles = await db.getMuscleGroupDistribution(days: 30);

    if (mounted) {
      setState(() {
        _workoutCount = count;
        _totalMinutes = minutes;
        _streak = streak;
        _weeklyVolume = volume;
        _muscleDistribution = muscles;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Progress & Stats')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Progress & Stats')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary cards
          Row(children: [
            _summaryCard('Total Workouts', '$_workoutCount', Icons.fitness_center, theme),
            const SizedBox(width: 8),
            _summaryCard('Total Minutes', '$_totalMinutes', Icons.timer, theme),
            const SizedBox(width: 8),
            _summaryCard('Current Streak', '$_streak days', Icons.local_fire_department, theme),
          ]),
          const SizedBox(height: 20),

          // Weekly volume chart
          Text('Weekly Volume', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Total weight × reps per week', style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: _weeklyVolume.isEmpty
                ? Center(child: Text('No data yet. Start logging workouts!', style: theme.textTheme.bodySmall))
                : _buildVolumeChart(theme),
          ),
          const SizedBox(height: 24),

          // Muscle group distribution
          Text('Muscle Group Focus (30 days)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: _muscleDistribution.isEmpty
                ? Center(child: Text('No data yet.', style: theme.textTheme.bodySmall))
                : _buildMuscleChart(theme),
          ),
          const SizedBox(height: 24),

          // Muscle breakdown list
          if (_muscleDistribution.isNotEmpty) ...[
            ...(_muscleDistribution.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
                .map((entry) => ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: _muscleColor(entry.key),
                child: Text('${entry.value}', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              title: Text(entry.key),
              subtitle: Text('${entry.value} sets logged'),
            )),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, ThemeData theme) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }

  Widget _buildVolumeChart(ThemeData theme) {
    final spots = _weeklyVolume.asMap().entries.map((entry) {
      final vol = (entry.value['volume'] as num?)?.toDouble() ?? 0;
      return FlSpot(entry.key.toDouble(), vol);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50,
            getTitlesWidget: (value, meta) => Text(_formatVolume(value), style: const TextStyle(fontSize: 10)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24,
            getTitlesWidget: (value, meta) => Text('W${value.toInt() + 1}', style: const TextStyle(fontSize: 10)))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            dotData: FlDotData(show: spots.length < 10),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withAlpha((0.1 * 255).round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleChart(ThemeData theme) {
    final entries = _muscleDistribution.entries.toList();
    final total = entries.fold(0, (sum, e) => sum + e.value);
    if (total == 0) return const SizedBox();

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: entries.map((e) {
          final pct = (e.value / total * 100);
          return PieChartSectionData(
            value: e.value.toDouble(),
            title: '${pct.toStringAsFixed(0)}%',
            color: _muscleColor(e.key),
            radius: 50,
            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
      ),
    );
  }

  Color _muscleColor(String group) {
    switch (group) {
      case 'Chest': return Colors.red.shade400;
      case 'Back': return Colors.blue.shade400;
      case 'Shoulders': return Colors.orange.shade400;
      case 'Arms': return Colors.purple.shade400;
      case 'Legs': return Colors.green.shade400;
      case 'Core': return Colors.teal.shade400;
      case 'Cardio': return Colors.pink.shade400;
      default: return Colors.grey;
    }
  }

  String _formatVolume(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}
