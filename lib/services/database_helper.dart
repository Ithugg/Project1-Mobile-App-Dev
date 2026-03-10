import 'package:sqflite/sqflite.dart';
import '../models/models.dart';

/// Centralized database helper for all SQLite operations.
/// Manages connections, schema creation, seeding, and CRUD for every table.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/fitness_quest.db';

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Create all tables and seed initial data
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        muscle_group TEXT NOT NULL,
        equipment TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0,
        image_path TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE quests (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        created_at TEXT NOT NULL,
        target_sessions INTEGER NOT NULL,
        completed_sessions INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE quest_exercises (
        id TEXT PRIMARY KEY,
        quest_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        target_sets INTEGER NOT NULL,
        target_reps INTEGER NOT NULL,
        target_weight REAL,
        order_index INTEGER NOT NULL,
        FOREIGN KEY (quest_id) REFERENCES quests(id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_logs (
        id TEXT PRIMARY KEY,
        quest_id TEXT NOT NULL,
        date TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        notes TEXT,
        rating INTEGER,
        FOREIGN KEY (quest_id) REFERENCES quests(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE set_logs (
        id TEXT PRIMARY KEY,
        workout_log_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        set_number INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL NOT NULL,
        completed INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (workout_log_id) REFERENCES workout_logs(id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        icon TEXT NOT NULL,
        unlock_criteria TEXT NOT NULL,
        unlocked_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_feedback (
        id TEXT PRIMARY KEY,
        suggestion_text TEXT NOT NULL,
        date TEXT NOT NULL,
        thumbs_up INTEGER
      )
    ''');

    // Seed exercises
    await _seedExercises(db);
    // Seed achievements
    await _seedAchievements(db);
  }

  /// Pre-populate the exercise library
  Future<void> _seedExercises(Database db) async {
    final exercises = [
      // Chest
      {'name': 'Bench Press', 'muscle_group': 'Chest', 'equipment': 'Barbell', 'difficulty': 'Intermediate'},
      {'name': 'Push-Ups', 'muscle_group': 'Chest', 'equipment': 'Bodyweight', 'difficulty': 'Beginner'},
      {'name': 'Dumbbell Fly', 'muscle_group': 'Chest', 'equipment': 'Dumbbells', 'difficulty': 'Intermediate'},
      {'name': 'Incline Press', 'muscle_group': 'Chest', 'equipment': 'Barbell', 'difficulty': 'Intermediate'},
      // Back
      {'name': 'Pull-Ups', 'muscle_group': 'Back', 'equipment': 'Bodyweight', 'difficulty': 'Intermediate'},
      {'name': 'Barbell Row', 'muscle_group': 'Back', 'equipment': 'Barbell', 'difficulty': 'Intermediate'},
      {'name': 'Lat Pulldown', 'muscle_group': 'Back', 'equipment': 'Machine', 'difficulty': 'Beginner'},
      {'name': 'Deadlift', 'muscle_group': 'Back', 'equipment': 'Barbell', 'difficulty': 'Advanced'},
      // Shoulders
      {'name': 'Overhead Press', 'muscle_group': 'Shoulders', 'equipment': 'Barbell', 'difficulty': 'Intermediate'},
      {'name': 'Lateral Raises', 'muscle_group': 'Shoulders', 'equipment': 'Dumbbells', 'difficulty': 'Beginner'},
      {'name': 'Face Pulls', 'muscle_group': 'Shoulders', 'equipment': 'Cable', 'difficulty': 'Beginner'},
      // Arms
      {'name': 'Bicep Curls', 'muscle_group': 'Arms', 'equipment': 'Dumbbells', 'difficulty': 'Beginner'},
      {'name': 'Tricep Dips', 'muscle_group': 'Arms', 'equipment': 'Bodyweight', 'difficulty': 'Intermediate'},
      {'name': 'Hammer Curls', 'muscle_group': 'Arms', 'equipment': 'Dumbbells', 'difficulty': 'Beginner'},
      // Legs
      {'name': 'Squats', 'muscle_group': 'Legs', 'equipment': 'Barbell', 'difficulty': 'Intermediate'},
      {'name': 'Lunges', 'muscle_group': 'Legs', 'equipment': 'Bodyweight', 'difficulty': 'Beginner'},
      {'name': 'Leg Press', 'muscle_group': 'Legs', 'equipment': 'Machine', 'difficulty': 'Beginner'},
      {'name': 'Romanian Deadlift', 'muscle_group': 'Legs', 'equipment': 'Barbell', 'difficulty': 'Advanced'},
      {'name': 'Calf Raises', 'muscle_group': 'Legs', 'equipment': 'Bodyweight', 'difficulty': 'Beginner'},
      // Core
      {'name': 'Plank', 'muscle_group': 'Core', 'equipment': 'Bodyweight', 'difficulty': 'Beginner'},
      {'name': 'Crunches', 'muscle_group': 'Core', 'equipment': 'Bodyweight', 'difficulty': 'Beginner'},
      {'name': 'Russian Twists', 'muscle_group': 'Core', 'equipment': 'Bodyweight', 'difficulty': 'Intermediate'},
      {'name': 'Hanging Leg Raise', 'muscle_group': 'Core', 'equipment': 'Bodyweight', 'difficulty': 'Advanced'},
      // Cardio
      {'name': 'Running', 'muscle_group': 'Cardio', 'equipment': 'None', 'difficulty': 'Beginner'},
      {'name': 'Jump Rope', 'muscle_group': 'Cardio', 'equipment': 'Jump Rope', 'difficulty': 'Beginner'},
      {'name': 'Burpees', 'muscle_group': 'Cardio', 'equipment': 'Bodyweight', 'difficulty': 'Advanced'},
    ];

    for (final e in exercises) {
      final exercise = Exercise(
        name: e['name']!,
        muscleGroup: e['muscle_group']!,
        equipment: e['equipment']!,
        difficulty: e['difficulty']!,
      );
      await db.insert('exercises', exercise.toMap());
    }
  }

  /// Pre-populate achievements
  Future<void> _seedAchievements(Database db) async {
    final achievements = [
      {'title': 'First Step', 'description': 'Complete your first workout', 'icon': 'directions_walk', 'criteria': 'complete_1_workout'},
      {'title': 'Week Warrior', 'description': 'Reach a 7-day streak', 'icon': 'local_fire_department', 'criteria': 'streak_7'},
      {'title': 'Quest Master', 'description': 'Complete your first quest', 'icon': 'emoji_events', 'criteria': 'complete_1_quest'},
      {'title': 'Iron Will', 'description': 'Log 10 workouts', 'icon': 'fitness_center', 'criteria': 'complete_10_workouts'},
      {'title': 'Consistency King', 'description': 'Reach a 30-day streak', 'icon': 'diamond', 'criteria': 'streak_30'},
      {'title': 'Gym Rat', 'description': 'Log 50 workouts', 'icon': 'military_tech', 'criteria': 'complete_50_workouts'},
      {'title': 'Century Club', 'description': 'Log 100 workouts', 'icon': 'star', 'criteria': 'complete_100_workouts'},
      {'title': 'Explorer', 'description': 'Use 10 different exercises', 'icon': 'explore', 'criteria': 'use_10_exercises'},
      {'title': 'Perfectionist', 'description': 'Rate a workout 5 stars', 'icon': 'thumb_up', 'criteria': 'rate_5_stars'},
      {'title': 'Multi-Tasker', 'description': 'Have 3 active quests at once', 'icon': 'flag', 'criteria': 'active_3_quests'},
    ];

    for (final a in achievements) {
      final achievement = Achievement(
        title: a['title']!,
        description: a['description']!,
        icon: a['icon']!,
        unlockCriteria: a['criteria']!,
      );
      await db.insert('achievements', achievement.toMap());
    }
  }

  // ===================== EXERCISE CRUD =====================

  Future<List<Exercise>> getExercises({String? muscleGroup, String? difficulty, String? search}) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> args = [];

    if (muscleGroup != null && muscleGroup.isNotEmpty) {
      where += ' AND muscle_group = ?';
      args.add(muscleGroup);
    }
    if (difficulty != null && difficulty.isNotEmpty) {
      where += ' AND difficulty = ?';
      args.add(difficulty);
    }
    if (search != null && search.isNotEmpty) {
      where += ' AND name LIKE ?';
      args.add('%$search%');
    }

    final maps = await db.query('exercises', where: where, whereArgs: args, orderBy: 'name');
    return maps.map((m) => Exercise.fromMap(m)).toList();
  }

  Future<Exercise?> getExercise(String id) async {
    final db = await database;
    final maps = await db.query('exercises', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Exercise.fromMap(maps.first);
  }

  Future<void> insertExercise(Exercise exercise) async {
    final db = await database;
    await db.insert('exercises', exercise.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateExercise(Exercise exercise) async {
    final db = await database;
    await db.update('exercises', exercise.toMap(), where: 'id = ?', whereArgs: [exercise.id]);
  }

  Future<void> deleteExercise(String id) async {
    final db = await database;
    await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  // ===================== QUEST CRUD =====================

  Future<List<Quest>> getQuests({bool? activeOnly}) async {
    final db = await database;
    String? where;
    List<dynamic>? args;
    if (activeOnly == true) {
      where = 'is_active = ?';
      args = [1];
    }
    final maps = await db.query('quests', where: where, whereArgs: args, orderBy: 'created_at DESC');
    List<Quest> quests = [];
    for (final m in maps) {
      final quest = Quest.fromMap(m);
      quest.exercises = await getQuestExercises(quest.id);
      quests.add(quest);
    }
    return quests;
  }

  Future<Quest?> getQuest(String id) async {
    final db = await database;
    final maps = await db.query('quests', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final quest = Quest.fromMap(maps.first);
    quest.exercises = await getQuestExercises(quest.id);
    return quest;
  }

  Future<void> insertQuest(Quest quest) async {
    final db = await database;
    await db.insert('quests', quest.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    for (final qe in quest.exercises) {
      await db.insert('quest_exercises', qe.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> updateQuest(Quest quest) async {
    final db = await database;
    await db.update('quests', quest.toMap(), where: 'id = ?', whereArgs: [quest.id]);
  }

  Future<void> deleteQuest(String id) async {
    final db = await database;
    await db.delete('quest_exercises', where: 'quest_id = ?', whereArgs: [id]);
    await db.delete('quests', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<QuestExercise>> getQuestExercises(String questId) async {
    final db = await database;
    final maps = await db.query('quest_exercises', where: 'quest_id = ?', whereArgs: [questId], orderBy: 'order_index');
    List<QuestExercise> list = [];
    for (final m in maps) {
      final qe = QuestExercise.fromMap(m);
      qe.exercise = await getExercise(qe.exerciseId);
      list.add(qe);
    }
    return list;
  }

  // ===================== WORKOUT LOG CRUD =====================

  Future<List<WorkoutLog>> getWorkoutLogs({String? questId, int? limit}) async {
    final db = await database;
    String? where;
    List<dynamic>? args;
    if (questId != null) {
      where = 'quest_id = ?';
      args = [questId];
    }
    final maps = await db.query('workout_logs', where: where, whereArgs: args, orderBy: 'date DESC', limit: limit);
    return maps.map((m) => WorkoutLog.fromMap(m)).toList();
  }

  Future<void> insertWorkoutLog(WorkoutLog log) async {
    final db = await database;
    await db.insert('workout_logs', log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    for (final s in log.sets) {
      await db.insert('set_logs', s.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    // Increment quest completed sessions
    await db.rawUpdate(
      'UPDATE quests SET completed_sessions = completed_sessions + 1 WHERE id = ?',
      [log.questId],
    );
  }

  Future<void> deleteWorkoutLog(String id) async {
    final db = await database;
    await db.delete('set_logs', where: 'workout_log_id = ?', whereArgs: [id]);
    await db.delete('workout_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SetLog>> getSetLogs(String workoutLogId) async {
    final db = await database;
    final maps = await db.query('set_logs', where: 'workout_log_id = ?', whereArgs: [workoutLogId], orderBy: 'set_number');
    return maps.map((m) => SetLog.fromMap(m)).toList();
  }

  // ===================== ACHIEVEMENTS =====================

  Future<List<Achievement>> getAchievements() async {
    final db = await database;
    final maps = await db.query('achievements');
    return maps.map((m) => Achievement.fromMap(m)).toList();
  }

  Future<void> unlockAchievement(String id) async {
    final db = await database;
    await db.update('achievements', {'unlocked_at': DateTime.now().toIso8601String()}, where: 'id = ? AND unlocked_at IS NULL', whereArgs: [id]);
  }

  // ===================== AI FEEDBACK =====================

  Future<void> insertAIFeedback(AIFeedback feedback) async {
    final db = await database;
    await db.insert('ai_feedback', feedback.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateAIFeedback(String id, bool thumbsUp) async {
    final db = await database;
    await db.update('ai_feedback', {'thumbs_up': thumbsUp ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<AIFeedback>> getAIFeedback({int? limit}) async {
    final db = await database;
    final maps = await db.query('ai_feedback', orderBy: 'date DESC', limit: limit);
    return maps.map((m) => AIFeedback.fromMap(m)).toList();
  }

  // ===================== STATS & ANALYTICS =====================

  /// Get workout count
  Future<int> getWorkoutCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM workout_logs');
    return result.first['count'] as int;
  }

  /// Get total workout minutes
  Future<int> getTotalMinutes() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COALESCE(SUM(duration_minutes), 0) as total FROM workout_logs');
    return result.first['total'] as int;
  }

  /// Get current streak (consecutive days with workouts ending today or yesterday)
  Future<int> getCurrentStreak() async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT DISTINCT date(date) as d FROM workout_logs ORDER BY d DESC',
    );
    if (maps.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();
    // Allow today or yesterday as start
    final firstLogDate = DateTime.parse(maps.first['d'] as String);
    final today = DateTime(checkDate.year, checkDate.month, checkDate.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (firstLogDate != today && firstLogDate != yesterday) return 0;

    checkDate = firstLogDate;
    for (final m in maps) {
      final logDate = DateTime.parse(m['d'] as String);
      final expected = DateTime(checkDate.year, checkDate.month, checkDate.day);
      if (logDate == expected) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  /// Get workout dates for heatmap (last N days)
  Future<Map<String, int>> getWorkoutDates({int days = 90}) async {
    final db = await database;
    final since = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final maps = await db.rawQuery(
      'SELECT date(date) as d, COUNT(*) as c FROM workout_logs WHERE date >= ? GROUP BY d',
      [since],
    );
    return {for (final m in maps) m['d'] as String: m['c'] as int};
  }

  /// Get weekly workout volume (total sets * reps * weight) for the last N weeks
  Future<List<Map<String, dynamic>>> getWeeklyVolume({int weeks = 8}) async {
    final db = await database;
    final since = DateTime.now().subtract(Duration(days: weeks * 7)).toIso8601String();
    final maps = await db.rawQuery('''
      SELECT strftime('%Y-%W', wl.date) as week,
             COALESCE(SUM(sl.reps * sl.weight), 0) as volume
      FROM workout_logs wl
      LEFT JOIN set_logs sl ON sl.workout_log_id = wl.id
      WHERE wl.date >= ?
      GROUP BY week
      ORDER BY week
    ''', [since]);
    return maps;
  }

  /// Get muscle group distribution from recent workouts
  Future<Map<String, int>> getMuscleGroupDistribution({int days = 30}) async {
    final db = await database;
    final since = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final maps = await db.rawQuery('''
      SELECT e.muscle_group, COUNT(*) as count
      FROM set_logs sl
      JOIN workout_logs wl ON sl.workout_log_id = wl.id
      JOIN exercises e ON sl.exercise_id = e.id
      WHERE wl.date >= ?
      GROUP BY e.muscle_group
    ''', [since]);
    return {for (final m in maps) m['muscle_group'] as String: m['count'] as int};
  }

  /// Get number of distinct exercises used
  Future<int> getDistinctExerciseCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(DISTINCT exercise_id) as count FROM set_logs');
    return result.first['count'] as int;
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
