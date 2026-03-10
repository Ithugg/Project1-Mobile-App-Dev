import '../models/models.dart';
import 'database_helper.dart';

/// Local rule-based AI trainer that suggests next workouts.
/// Analyzes recent workout history to recommend balanced training.
class AITrainerService {
  final DatabaseHelper _db;

  AITrainerService(this._db);

  /// Generate a workout suggestion with explanation
  Future<AISuggestion> getSuggestion() async {
    final logs = await _db.getWorkoutLogs(limit: 20);
    final muscleDistribution = await _db.getMuscleGroupDistribution(days: 7);
    final streak = await _db.getCurrentStreak();
    final workoutCount = await _db.getWorkoutCount();

    // All possible muscle groups
    const allGroups = ['Chest', 'Back', 'Shoulders', 'Arms', 'Legs', 'Core', 'Cardio'];

    // If no workouts yet, suggest a beginner-friendly start
    if (logs.isEmpty) {
      return AISuggestion(
        title: 'Start Your Journey!',
        muscleGroup: 'Legs',
        reasoning: 'Welcome! Legs are the largest muscle group — a great place to start building strength and burning calories.',
        exercises: ['Squats', 'Lunges', 'Calf Raises', 'Plank'],
        intensity: 'Beginner',
      );
    }

    // Find the least-trained muscle group in the last 7 days
    String leastTrained = allGroups.first;
    int minCount = 999;
    for (final group in allGroups) {
      final count = muscleDistribution[group] ?? 0;
      if (count < minCount) {
        minCount = count;
        leastTrained = group;
      }
    }

    // Check days since last workout
    final daysSinceLastWorkout = DateTime.now().difference(logs.first.date).inDays;

    // Determine intensity based on recent activity
    String intensity;
    String reasoning;

    if (daysSinceLastWorkout >= 3) {
      // Long rest — suggest moderate restart
      intensity = 'Beginner';
      reasoning = "You haven't worked out in $daysSinceLastWorkout days. Let's ease back in with a moderate $leastTrained session to rebuild momentum.";
    } else if (streak >= 5) {
      // On a good streak — check for overtraining
      intensity = 'Intermediate';
      reasoning = "Great $streak-day streak! Your $leastTrained could use attention — you've only hit it ${muscleDistribution[leastTrained] ?? 0} time(s) this week.";
    } else {
      intensity = 'Intermediate';
      reasoning = "$leastTrained is your least-trained group this week (${muscleDistribution[leastTrained] ?? 0} sessions). Balancing your training will help avoid imbalances.";
    }

    // Check user feedback patterns
    final feedback = await _db.getAIFeedback(limit: 10);
    final thumbsDownCount = feedback.where((f) => f.thumbsUp == false).length;
    if (thumbsDownCount > 5) {
      // User often disagrees — add variety
      reasoning += ' Mixing in some variety based on your preferences.';
    }

    // Build exercise suggestions based on muscle group
    final exercises = await _db.getExercises(muscleGroup: leastTrained, difficulty: intensity);
    final exerciseNames = exercises.take(4).map((e) => e.name).toList();
    if (exerciseNames.isEmpty) {
      // Fallback if no exercises match the exact difficulty
      final fallback = await _db.getExercises(muscleGroup: leastTrained);
      exerciseNames.addAll(fallback.take(4).map((e) => e.name));
    }

    // Add a title
    String title;
    if (daysSinceLastWorkout >= 3) {
      title = 'Welcome Back: $leastTrained Focus';
    } else if (workoutCount < 5) {
      title = 'Building Foundations: $leastTrained Day';
    } else {
      title = '$leastTrained Power Session';
    }

    return AISuggestion(
      title: title,
      muscleGroup: leastTrained,
      reasoning: reasoning,
      exercises: exerciseNames,
      intensity: intensity,
    );
  }

  /// Save feedback for a suggestion
  Future<void> saveFeedback(String suggestionText, bool? thumbsUp) async {
    final feedback = AIFeedback(
      suggestionText: suggestionText,
      thumbsUp: thumbsUp,
    );
    await _db.insertAIFeedback(feedback);
  }
}

/// Represents an AI-generated workout suggestion
class AISuggestion {
  final String title;
  final String muscleGroup;
  final String reasoning;
  final List<String> exercises;
  final String intensity;

  AISuggestion({
    required this.title,
    required this.muscleGroup,
    required this.reasoning,
    required this.exercises,
    required this.intensity,
  });
}
