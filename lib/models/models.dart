import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Exercise model - represents a single exercise in the library
class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final String equipment;
  final String difficulty; // 'Beginner', 'Intermediate', 'Advanced'
  final bool isCustom;
  final String? imagePath;
  final String? notes;

  Exercise({
    String? id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.difficulty,
    this.isCustom = false,
    this.imagePath,
    this.notes,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'muscle_group': muscleGroup,
        'equipment': equipment,
        'difficulty': difficulty,
        'is_custom': isCustom ? 1 : 0,
        'image_path': imagePath,
        'notes': notes,
      };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id'],
        name: map['name'],
        muscleGroup: map['muscle_group'],
        equipment: map['equipment'],
        difficulty: map['difficulty'],
        isCustom: map['is_custom'] == 1,
        imagePath: map['image_path'],
        notes: map['notes'],
      );
}

/// Quest model - a workout mission with a target number of sessions
class Quest {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final int targetSessions;
  int completedSessions;
  bool isActive;
  List<QuestExercise> exercises;

  Quest({
    String? id,
    required this.title,
    required this.description,
    DateTime? createdAt,
    required this.targetSessions,
    this.completedSessions = 0,
    this.isActive = true,
    this.exercises = const [],
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  double get progress =>
      targetSessions > 0 ? completedSessions / targetSessions : 0.0;

  bool get isCompleted => completedSessions >= targetSessions;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'created_at': createdAt.toIso8601String(),
        'target_sessions': targetSessions,
        'completed_sessions': completedSessions,
        'is_active': isActive ? 1 : 0,
      };

  factory Quest.fromMap(Map<String, dynamic> map) => Quest(
        id: map['id'],
        title: map['title'],
        description: map['description'],
        createdAt: DateTime.parse(map['created_at']),
        targetSessions: map['target_sessions'],
        completedSessions: map['completed_sessions'],
        isActive: map['is_active'] == 1,
      );
}

/// Links one of the exercise to a quest with target sets/reps/weight
class QuestExercise {
  final String id;
  final String questId;
  final String exerciseId;
  final int targetSets;
  final int targetReps;
  final double? targetWeight;
  final int orderIndex;
  Exercise? exercise; // populated via join

  QuestExercise({
    String? id,
    required this.questId,
    required this.exerciseId,
    required this.targetSets,
    required this.targetReps,
    this.targetWeight,
    required this.orderIndex,
    this.exercise,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'quest_id': questId,
        'exercise_id': exerciseId,
        'target_sets': targetSets,
        'target_reps': targetReps,
        'target_weight': targetWeight,
        'order_index': orderIndex,
      };

  factory QuestExercise.fromMap(Map<String, dynamic> map) => QuestExercise(
        id: map['id'],
        questId: map['quest_id'],
        exerciseId: map['exercise_id'],
        targetSets: map['target_sets'],
        targetReps: map['target_reps'],
        targetWeight: map['target_weight'] != null
            ? (map['target_weight'] as num).toDouble()
            : null,
        orderIndex: map['order_index'],
      );
}

/// A single logged workout session
class WorkoutLog {
  final String id;
  final String questId;
  final DateTime date;
  final int durationMinutes;
  final String? notes;
  final int? rating; // 1-5 stars
  List<SetLog> sets;

  WorkoutLog({
    String? id,
    required this.questId,
    DateTime? date,
    required this.durationMinutes,
    this.notes,
    this.rating,
    this.sets = const [],
  })  : id = id ?? _uuid.v4(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'quest_id': questId,
        'date': date.toIso8601String(),
        'duration_minutes': durationMinutes,
        'notes': notes,
        'rating': rating,
      };

  factory WorkoutLog.fromMap(Map<String, dynamic> map) => WorkoutLog(
        id: map['id'],
        questId: map['quest_id'],
        date: DateTime.parse(map['date']),
        durationMinutes: map['duration_minutes'],
        notes: map['notes'],
        rating: map['rating'],
      );
}

/// A single set within a workout log
class SetLog {
  final String id;
  final String workoutLogId;
  final String exerciseId;
  final int setNumber;
  final int reps;
  final double weight;
  final bool completed;

  SetLog({
    String? id,
    required this.workoutLogId,
    required this.exerciseId,
    required this.setNumber,
    required this.reps,
    required this.weight,
    this.completed = true,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'workout_log_id': workoutLogId,
        'exercise_id': exerciseId,
        'set_number': setNumber,
        'reps': reps,
        'weight': weight,
        'completed': completed ? 1 : 0,
      };

  factory SetLog.fromMap(Map<String, dynamic> map) => SetLog(
        id: map['id'],
        workoutLogId: map['workout_log_id'],
        exerciseId: map['exercise_id'],
        setNumber: map['set_number'],
        reps: map['reps'],
        weight: (map['weight'] as num).toDouble(),
        completed: map['completed'] == 1,
      );
}

/// Achievement / badge model
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon; // Material icon name
  final String unlockCriteria;
  DateTime? unlockedAt;

  Achievement({
    String? id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlockCriteria,
    this.unlockedAt,
  }) : id = id ?? _uuid.v4();

  bool get isUnlocked => unlockedAt != null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'icon': icon,
        'unlock_criteria': unlockCriteria,
        'unlocked_at': unlockedAt?.toIso8601String(),
      };

  factory Achievement.fromMap(Map<String, dynamic> map) => Achievement(
        id: map['id'],
        title: map['title'],
        description: map['description'],
        icon: map['icon'],
        unlockCriteria: map['unlock_criteria'],
        unlockedAt: map['unlocked_at'] != null
            ? DateTime.parse(map['unlocked_at'])
            : null,
      );
}

/// AI trainer feedback record
class AIFeedback {
  final String id;
  final String suggestionText;
  final DateTime date;
  final bool? thumbsUp; // null = no feedback yet

  AIFeedback({
    String? id,
    required this.suggestionText,
    DateTime? date,
    this.thumbsUp,
  })  : id = id ?? _uuid.v4(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'suggestion_text': suggestionText,
        'date': date.toIso8601String(),
        'thumbs_up': thumbsUp == null ? null : (thumbsUp! ? 1 : 0),
      };

  factory AIFeedback.fromMap(Map<String, dynamic> map) => AIFeedback(
        id: map['id'],
        suggestionText: map['suggestion_text'],
        date: DateTime.parse(map['date']),
        thumbsUp: map['thumbs_up'] == null ? null : map['thumbs_up'] == 1,
      );
}
