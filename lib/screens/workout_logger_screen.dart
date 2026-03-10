import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import '../services/achievement_checker.dart';
import '../models/models.dart';

/// Active workout session screen for a specific quest.
/// Tracks sets, reps, weight, has a timer, and logs completion.
class WorkoutLoggerScreen extends StatefulWidget {
  final Quest quest;
  const WorkoutLoggerScreen({super.key, required this.quest});

  @override
  State<WorkoutLoggerScreen> createState() => _WorkoutLoggerScreenState();
}

class _WorkoutLoggerScreenState extends State<WorkoutLoggerScreen> {
  late List<_ExerciseProgress> _exerciseProgress;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  int _rating = 0;
  final _notesCtrl = TextEditingController();
  bool _saving = false;
  bool _workoutStarted = false;

  @override
  void initState() {
    super.initState();
    _exerciseProgress = widget.quest.exercises.map((qe) {
      return _ExerciseProgress(
        questExercise: qe,
        setData: List.generate(qe.targetSets, (i) => _SetData(
          setNumber: i + 1,
          targetReps: qe.targetReps,
          targetWeight: qe.targetWeight ?? 0,
        )),
      );
    }).toList();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _startWorkout() {
    setState(() {
      _workoutStarted = true;
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours;
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }

  int get _completedSets {
    int count = 0;
    for (final ep in _exerciseProgress) {
      for (final s in ep.setData) {
        if (s.completed) count++;
      }
    }
    return count;
  }

  int get _totalSets {
    int count = 0;
    for (final ep in _exerciseProgress) {
      count += ep.setData.length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quest.title),
        actions: [
          if (_workoutStarted)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  _formatDuration(_stopwatch.elapsed),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: !_workoutStarted
          ? _buildStartView(theme)
          : Column(
              children: [
                // Progress bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _totalSets > 0 ? _completedSets / _totalSets : 0,
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('$_completedSets/$_totalSets sets', style: theme.textTheme.bodySmall),
                  ]),
                ),
                // Exercise list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _exerciseProgress.length,
                    itemBuilder: (context, index) => _buildExerciseCard(_exerciseProgress[index], theme),
                  ),
                ),
                // Finish button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _finishWorkout,
                      icon: const Icon(Icons.check),
                      label: const Text('Finish Workout'),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStartView(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(widget.quest.title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('${widget.quest.exercises.length} exercises • ${widget.quest.completedSessions}/${widget.quest.targetSessions} sessions done',
            style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          // Exercise preview
          ...widget.quest.exercises.map((qe) => ListTile(
            dense: true,
            leading: const Icon(Icons.circle_outlined, size: 16),
            title: Text(qe.exercise?.name ?? 'Unknown'),
            subtitle: Text('${qe.targetSets} sets × ${qe.targetReps} reps'),
          )),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _startWorkout,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Workout'),
            style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(_ExerciseProgress ep, ThemeData theme) {
    final name = ep.questExercise.exercise?.name ?? 'Exercise';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Header row
            const Row(children: [
              SizedBox(width: 40, child: Text('Set', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(child: Text('Reps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(child: Text('Weight', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              SizedBox(width: 48, child: Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
            ]),
            const Divider(height: 8),
            // Set rows
            ...ep.setData.map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                SizedBox(width: 40, child: Text('${s.setNumber}', style: theme.textTheme.bodyMedium)),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: TextEditingController(text: '${s.targetReps}'),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                      style: const TextStyle(fontSize: 14),
                      onChanged: (v) => s.actualReps = int.tryParse(v) ?? s.targetReps,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: TextEditingController(text: '${s.targetWeight}'),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                      style: const TextStyle(fontSize: 14),
                      onChanged: (v) => s.actualWeight = double.tryParse(v) ?? s.targetWeight,
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Checkbox(
                    value: s.completed,
                    onChanged: (v) => setState(() => s.completed = v ?? false),
                  ),
                ),
              ]),
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _finishWorkout() async {
    _stopwatch.stop();
    _timer?.cancel();

    // Show rating dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Workout Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was your workout?'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(i < _rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
                  onPressed: () => setDialogState(() => _rating = i + 1),
                )),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes (optional)', hintText: 'How did it feel?'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    setState(() => _saving = true);

    if (!mounted) return;
    final db = context.read<DatabaseHelper>();
    final durationMinutes = _stopwatch.elapsed.inMinutes.clamp(1, 999);

    // Build set logs
    List<SetLog> allSets = [];
    final logId = DateTime.now().millisecondsSinceEpoch.toString();

    for (final ep in _exerciseProgress) {
      for (final s in ep.setData) {
        if (s.completed) {
          allSets.add(SetLog(
            workoutLogId: logId,
            exerciseId: ep.questExercise.exerciseId,
            setNumber: s.setNumber,
            reps: s.actualReps ?? s.targetReps,
            weight: s.actualWeight ?? s.targetWeight,
          ));
        }
      }
    }

    final workoutLog = WorkoutLog(
      id: logId,
      questId: widget.quest.id,
      durationMinutes: durationMinutes,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      rating: _rating > 0 ? _rating : null,
      sets: allSets,
    );

    await db.insertWorkoutLog(workoutLog);

    // Check achievements
    final checker = AchievementChecker(db);
    final newBadges = await checker.checkAll();

    if (mounted) {
      if (newBadges.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Badge unlocked: ${newBadges.join(", ")}!'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.amber.shade700,
          ),
        );
      }
      Navigator.pop(context, true);
    }
  }
}

class _ExerciseProgress {
  final QuestExercise questExercise;
  final List<_SetData> setData;

  _ExerciseProgress({required this.questExercise, required this.setData});
}

class _SetData {
  final int setNumber;
  final int targetReps;
  final double targetWeight;
  int? actualReps;
  double? actualWeight;
  late bool completed;

  _SetData({
    required this.setNumber,
    required this.targetReps,
    required this.targetWeight,
    this.actualReps,
    this.actualWeight,
    bool completed = false,
  }) {
    this.completed = completed;
  }
}
