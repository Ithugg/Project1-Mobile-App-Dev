import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import 'achievements_screen.dart';

/// Profile and settings screen.
/// Shows user info, preferences, dark mode toggle, and achievements link.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _workoutCount = 0;
  int _questCount = 0;
  int _badgeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db = context.read<DatabaseHelper>();
    final workouts = await db.getWorkoutCount();
    final quests = await db.getQuests();
    final achievements = await db.getAchievements();
    final unlocked = achievements.where((a) => a.isUnlocked).length;

    if (mounted) {
      setState(() {
        _workoutCount = workouts;
        _questCount = quests.length;
        _badgeCount = unlocked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = context.watch<PreferencesService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.person, size: 40, color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 12),
                Text(prefs.userName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(prefs.fitnessGoal, style: theme.textTheme.bodySmall),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _miniStat('$_workoutCount', 'Workouts', theme),
                    _miniStat('$_questCount', 'Quests', theme),
                    _miniStat('$_badgeCount', 'Badges', theme),
                  ],
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // Achievements
          Card(
            child: ListTile(
              leading: const Icon(Icons.emoji_events, color: Colors.amber),
              title: const Text('Achievements'),
              subtitle: Text('$_badgeCount unlocked'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AchievementsScreen()),
              ).then((_) => _loadStats()),
            ),
          ),
          const SizedBox(height: 16),

          // Settings section
          Text('Settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Dark mode
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode),
              title: const Text('Dark Mode'),
              value: prefs.isDarkMode,
              onChanged: (v) => prefs.setDarkMode(v),
            ),
          ),

          // Weight unit
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.monitor_weight),
              title: const Text('Use Kilograms'),
              subtitle: Text(prefs.useKg ? 'kg' : 'lbs'),
              value: prefs.useKg,
              onChanged: (v) => prefs.setUseKg(v),
            ),
          ),

          // Edit name
          Card(
            child: ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Name'),
              subtitle: Text(prefs.userName),
              onTap: () => _editField('Name', prefs.userName, (v) => prefs.setUserName(v)),
            ),
          ),

          // Edit goal
          Card(
            child: ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Fitness Goal'),
              subtitle: Text(prefs.fitnessGoal),
              onTap: () => _editField('Fitness Goal', prefs.fitnessGoal, (v) => prefs.setFitnessGoal(v)),
            ),
          ),

          // Weekly target
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Weekly Workout Target'),
              subtitle: Text('${prefs.weeklyTarget} workouts/week'),
              onTap: () => _editWeeklyTarget(prefs),
            ),
          ),

          const SizedBox(height: 16),

          // Data section
          Text('Data', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Export data
          Card(
            child: ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Data (JSON)'),
              subtitle: const Text('Save workout history for backup'),
              onTap: _exportData,
            ),
          ),

          const SizedBox(height: 24),

          // App info
          Center(
            child: Text('Fitness Quest v1.0.0\nBuilt with Flutter & SQLite',
              style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label, ThemeData theme) {
    return Column(children: [
      Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      Text(label, style: theme.textTheme.bodySmall),
    ]);
  }

  Future<void> _editField(String label, String currentValue, Future<void> Function(String) onSave) async {
    final ctrl = TextEditingController(text: currentValue);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(controller: ctrl, autofocus: true, decoration: InputDecoration(labelText: label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await onSave(result);
    }
  }

  Future<void> _editWeeklyTarget(PreferencesService prefs) async {
    int target = prefs.weeklyTarget;
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Weekly Target'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$target workouts per week', style: Theme.of(ctx).textTheme.titleLarge),
              Slider(
                value: target.toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                label: '$target',
                onChanged: (v) => setDialogState(() => target = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, target), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (result != null) await prefs.setWeeklyTarget(result);
  }

  Future<void> _exportData() async {
    final db = context.read<DatabaseHelper>();
    final logs = await db.getWorkoutLogs();
    final quests = await db.getQuests();

    final data = {
      'exported_at': DateTime.now().toIso8601String(),
      'app': 'Fitness Quest',
      'quests': quests.map((q) => q.toMap()).toList(),
      'workout_logs': logs.map((l) => l.toMap()).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Data Exported'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: SingleChildScrollView(
              child: SelectableText(jsonStr, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    }
  }
}
