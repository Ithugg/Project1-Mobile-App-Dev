import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';
import '../models/models.dart';

/// Badge gallery showing all achievements — earned and locked.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<Achievement> _achievements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final db = context.read<DatabaseHelper>();
    final achievements = await db.getAchievements();
    // Sort: unlocked first, then by title
    achievements.sort((a, b) {
      if (a.isUnlocked && !b.isUnlocked) return -1;
      if (!a.isUnlocked && b.isUnlocked) return 1;
      return a.title.compareTo(b.title);
    });
    if (mounted) setState(() { _achievements = achievements; _loading = false; });
  }

  /// Map icon name string to IconData
  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'directions_walk': return Icons.directions_walk;
      case 'local_fire_department': return Icons.local_fire_department;
      case 'emoji_events': return Icons.emoji_events;
      case 'fitness_center': return Icons.fitness_center;
      case 'diamond': return Icons.diamond;
      case 'military_tech': return Icons.military_tech;
      case 'star': return Icons.star;
      case 'explore': return Icons.explore;
      case 'thumb_up': return Icons.thumb_up;
      case 'flag': return Icons.flag;
      default: return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = _achievements.where((a) => a.isUnlocked).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                    const SizedBox(width: 8),
                    Text('$unlocked / ${_achievements.length} Unlocked',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ]),
                ),
                // Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _achievements.length,
                    itemBuilder: (context, index) {
                      final a = _achievements[index];
                      return _buildBadgeCard(a, theme);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBadgeCard(Achievement achievement, ThemeData theme) {
    final isUnlocked = achievement.isUnlocked;

    return Card(
      color: isUnlocked ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(achievement),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIcon(achievement.icon),
                size: 36,
                color: isUnlocked ? Colors.amber : theme.colorScheme.outline,
              ),
              const SizedBox(height: 8),
              Text(
                achievement.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                achievement.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isUnlocked
                      ? theme.colorScheme.onPrimaryContainer.withAlpha((0.7 * 255).round())
                      : theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isUnlocked && achievement.unlockedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat.yMMMd().format(achievement.unlockedAt!),
                    style: TextStyle(fontSize: 10, color: theme.colorScheme.onPrimaryContainer.withAlpha((0.5 * 255).round())),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(Achievement achievement) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getIcon(achievement.icon), size: 48, color: achievement.isUnlocked ? Colors.amber : Colors.grey),
            const SizedBox(height: 12),
            Text(achievement.title, style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(achievement.description, style: Theme.of(ctx).textTheme.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              achievement.isUnlocked
                  ? 'Unlocked on ${DateFormat.yMMMd().format(achievement.unlockedAt!)}'
                  : 'Not yet unlocked',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
