import 'database_helper.dart';

/// Checks and unlocks achievements based on current user progress.
/// Call after every workout log to see if new badges are earned.
class AchievementChecker {
  final DatabaseHelper _db;

  AchievementChecker(this._db);

  /// Check all achievements and unlock any that are newly earned.
  /// Returns a list of newly unlocked achievement titles.
  Future<List<String>> checkAll() async {
    final achievements = await _db.getAchievements();
    final workoutCount = await _db.getWorkoutCount();
    final streak = await _db.getCurrentStreak();
    final distinctExercises = await _db.getDistinctExerciseCount();
    final quests = await _db.getQuests();
    final completedQuests = quests.where((q) => q.isCompleted).length;
    final activeQuests = quests.where((q) => q.isActive && !q.isCompleted).length;
    final logs = await _db.getWorkoutLogs(limit: 1);
    final hasRated5 = logs.isNotEmpty && logs.any((l) => l.rating == 5);

    List<String> newlyUnlocked = [];

    for (final a in achievements) {
      if (a.isUnlocked) continue;

      bool shouldUnlock = false;

      switch (a.unlockCriteria) {
        case 'complete_1_workout':
          shouldUnlock = workoutCount >= 1;
          break;
        case 'complete_10_workouts':
          shouldUnlock = workoutCount >= 10;
          break;
        case 'complete_50_workouts':
          shouldUnlock = workoutCount >= 50;
          break;
        case 'complete_100_workouts':
          shouldUnlock = workoutCount >= 100;
          break;
        case 'streak_7':
          shouldUnlock = streak >= 7;
          break;
        case 'streak_30':
          shouldUnlock = streak >= 30;
          break;
        case 'complete_1_quest':
          shouldUnlock = completedQuests >= 1;
          break;
        case 'use_10_exercises':
          shouldUnlock = distinctExercises >= 10;
          break;
        case 'rate_5_stars':
          shouldUnlock = hasRated5;
          break;
        case 'active_3_quests':
          shouldUnlock = activeQuests >= 3;
          break;
      }

      if (shouldUnlock) {
        await _db.unlockAchievement(a.id);
        newlyUnlocked.add(a.title);
      }
    }

    return newlyUnlocked;
  }
}
