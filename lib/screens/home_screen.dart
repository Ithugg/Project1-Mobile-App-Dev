import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';
import '../services/ai_trainer_service.dart';
import '../services/preferences_service.dart';
import '../models/models.dart';
import 'progress_screen.dart';
import 'workout_logger_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _workoutCount = 0;
  int _totalMinutes = 0;
  int _streak = 0;
  List<Quest> _activeQuests = [];
  AISuggestion? _suggestion;
  Map<String, int> _workoutDates = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = context.read<DatabaseHelper>();
    final ai = context.read<AITrainerService>();

    final count = await db.getWorkoutCount();
    final minutes = await db.getTotalMinutes();
    final streak = await db.getCurrentStreak();
    final quests = await db.getQuests(activeOnly: true);
    final suggestion = await ai.getSuggestion();
    final dates = await db.getWorkoutDates(days: 35);

    if (mounted) {
      setState(() {
        _workoutCount = count;
        _totalMinutes = minutes;
        _streak = streak;
        _activeQuests = quests.where((q) => !q.isCompleted).toList();
        _suggestion = suggestion;
        _workoutDates = dates;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesService>();
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverAppBar.large(
              title: Text('Hey, ${prefs.userName}!'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.bar_chart),
                  tooltip: 'View Stats',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProgressScreen()),
                  ).then((_) => _loadData()),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Stats row
                  _buildStatsRow(theme),
                  const SizedBox(height: 16),
                  // Streak heatmap
                  _buildStreakCard(theme),
                  const SizedBox(height: 16),
                  // AI suggestion
                  if (_suggestion != null) _buildAISuggestionCard(theme),
                  const SizedBox(height: 16),
                  // Active quests
                  Text('Active Quests', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_activeQuests.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(children: [
                          Icon(Icons.flag_outlined, size: 48, color: theme.colorScheme.outline),
                          const SizedBox(height: 8),
                          Text('No active quests yet', style: theme.textTheme.bodyLarge),
                          const SizedBox(height: 4),
                          Text('Go to the Quests tab to create one!', style: theme.textTheme.bodySmall),
                        ]),
                      ),
                    ),
                  ..._activeQuests.map((q) => _buildQuestCard(q, theme)),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    return Row(
      children: [
        _statCard('Workouts', '$_workoutCount', Icons.fitness_center, theme),
        const SizedBox(width: 8),
        _statCard('Minutes', '$_totalMinutes', Icons.timer, theme),
        const SizedBox(width: 8),
        _statCard('Streak', '$_streak day${_streak == 1 ? '' : 's'}', Icons.local_fire_department, theme),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, ThemeData theme) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: theme.textTheme.bodySmall),
          ]),
        ),
      ),
    );
  }

  Widget _buildStreakCard(ThemeData theme) {
    // Simple 5-week heatmap (last 35 days)
    final today = DateTime.now();
    final days = List.generate(35, (i) => today.subtract(Duration(days: 34 - i)));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.calendar_month, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Activity (Last 5 Weeks)', style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 12),
            // Heatmap grid
            SizedBox(
              height: 80,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 3,
                  crossAxisSpacing: 3,
                ),
                itemCount: 35,
                itemBuilder: (context, index) {
                  final day = days[index];
                  final key = DateFormat('yyyy-MM-dd').format(day);
                  final count = _workoutDates[key] ?? 0;
                  final isToday = index == 34;

                  Color color;
                  if (count == 0) {
                    color = theme.colorScheme.surfaceContainerHighest;
                  } else if (count == 1) {
                    color = theme.colorScheme.primary.withAlpha((0.4 * 255).round());
                  } else {
                    color = theme.colorScheme.primary;
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                      border: isToday ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAISuggestionCard(ThemeData theme) {
    final ai = context.read<AITrainerService>();

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.auto_awesome, size: 20, color: theme.colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Text('AI Trainer Suggestion', style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              )),
            ]),
            const SizedBox(height: 8),
            Text(_suggestion!.title, style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 4),
            Text(_suggestion!.reasoning, style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withAlpha((0.8 * 255).round()),
            )),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _suggestion!.exercises.map((e) => Chip(
                label: Text(e, style: const TextStyle(fontSize: 12)),
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
            const SizedBox(height: 8),
            // Feedback row
            Row(
              children: [
                Text('Helpful?', style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer.withAlpha((0.7 * 255).round()),
                )),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.thumb_up, size: 18),
                  onPressed: () async {
                    await ai.saveFeedback(_suggestion!.title, true);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thanks for the feedback!'), duration: Duration(seconds: 1)),
                      );
                    }
                  },
                ),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  icon: const Icon(Icons.thumb_down, size: 18),
                  onPressed: () async {
                    await ai.saveFeedback(_suggestion!.title, false);
                    _loadData(); // Refresh for a new suggestion
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestCard(Quest quest, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WorkoutLoggerScreen(quest: quest)),
          ).then((_) => _loadData());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(quest.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
                  Text('${quest.completedSessions}/${quest.targetSessions}', style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 4),
              Text(quest.description, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: quest.progress.clamp(0.0, 1.0),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Text('${quest.exercises.length} exercises • Tap to start workout',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
            ],
          ),
        ),
      ),
    );
  }
}
