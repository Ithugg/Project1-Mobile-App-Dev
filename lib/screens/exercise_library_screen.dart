import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import '../models/models.dart';

/// Browsable,searchable, and filterable exercise library with add-custom capability.
class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  List<Exercise> _exercises = [];
  String _searchQuery = '';
  String? _selectedMuscle;
  String? _selectedDifficulty;
  bool _loading = true;

  static const _muscleGroups = [
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Legs',
    'Core',
    'Cardio'
  ];
  static const _difficulties = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final db = context.read<DatabaseHelper>();
    final exercises = await db.getExercises(
      muscleGroup: _selectedMuscle,
      difficulty: _selectedDifficulty,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
    if (mounted)
      setState(() {
        _exercises = exercises;
        _loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Library')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExerciseDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                          _loadExercises();
                        })
                    : null,
              ),
              onChanged: (v) {
                _searchQuery = v;
                _loadExercises();
              },
            ),
          ),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              // Muscle group filter
              ...(_muscleGroups.map((m) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(m),
                      selected: _selectedMuscle == m,
                      onSelected: (selected) {
                        setState(() => _selectedMuscle = selected ? m : null);
                        _loadExercises();
                      },
                    ),
                  ))),
              const SizedBox(width: 8),
              // Difficulty filter
              ...(_difficulties.map((d) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(d),
                      selected: _selectedDifficulty == d,
                      onSelected: (selected) {
                        setState(
                            () => _selectedDifficulty = selected ? d : null);
                        _loadExercises();
                      },
                    ),
                  ))),
            ]),
          ),
          const Divider(height: 1),
          // Exercise list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _exercises.isEmpty
                    ? Center(
                        child: Text('No exercises found',
                            style: theme.textTheme.bodyLarge))
                    : RefreshIndicator(
                        onRefresh: _loadExercises,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _exercises.length,
                          itemBuilder: (context, index) =>
                              _buildExerciseTile(_exercises[index], theme),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseTile(Exercise exercise, ThemeData theme) {
    // Icon based on muscle group
    IconData icon;
    switch (exercise.muscleGroup) {
      case 'Chest':
        icon = Icons.airline_seat_flat;
        break;
      case 'Back':
        icon = Icons.accessibility_new;
        break;
      case 'Shoulders':
        icon = Icons.expand_less;
        break;
      case 'Arms':
        icon = Icons.front_hand;
        break;
      case 'Legs':
        icon = Icons.directions_walk;
        break;
      case 'Core':
        icon = Icons.circle_outlined;
        break;
      case 'Cardio':
        icon = Icons.favorite;
        break;
      default:
        icon = Icons.fitness_center;
    }

    // Difficulty color
    Color diffColor;
    switch (exercise.difficulty) {
      case 'Beginner':
        diffColor = Colors.green;
        break;
      case 'Intermediate':
        diffColor = Colors.orange;
        break;
      case 'Advanced':
        diffColor = Colors.red;
        break;
      default:
        diffColor = Colors.grey;
    }

    return Dismissible(
      key: Key(exercise.id),
      direction: exercise.isCustom
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: theme.colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Exercise?'),
            content: const Text('This will remove the custom exercise.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete')),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        final db = context.read<DatabaseHelper>();
        await db.deleteExercise(exercise.id);
        _loadExercises();
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child:
              Icon(icon, color: theme.colorScheme.onPrimaryContainer, size: 20),
        ),
        title: Text(exercise.name),
        subtitle: Text('${exercise.muscleGroup} • ${exercise.equipment}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: diffColor.withAlpha((0.15 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(exercise.difficulty,
              style: TextStyle(
                  fontSize: 11, color: diffColor, fontWeight: FontWeight.bold)),
        ),
        onTap: () => _showExerciseDetail(exercise),
      ),
    );
  }

  void _showExerciseDetail(Exercise exercise) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exercise.name, style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 12),
            _detailRow('Muscle Group', exercise.muscleGroup),
            _detailRow('Equipment', exercise.equipment),
            _detailRow('Difficulty', exercise.difficulty),
            _detailRow('Type', exercise.isCustom ? 'Custom' : 'Built-in'),
            if (exercise.notes != null && exercise.notes!.isNotEmpty)
              _detailRow('Notes', exercise.notes!),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Text(value)),
      ]),
    );
  }

  /// Dialog to add a custom exercise
  Future<void> _showAddExerciseDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String muscleGroup = 'Chest';
    String equipment = 'Bodyweight';
    String difficulty = 'Beginner';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Custom Exercise'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Exercise Name')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: muscleGroup,
                  decoration: const InputDecoration(labelText: 'Muscle Group'),
                  items: _muscleGroups
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => muscleGroup = v!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: difficulty,
                  decoration: const InputDecoration(labelText: 'Difficulty'),
                  items: _difficulties
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => difficulty = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: TextEditingController(text: equipment),
                  decoration: const InputDecoration(labelText: 'Equipment'),
                  onChanged: (v) => equipment = v,
                ),
                const SizedBox(height: 8),
                TextField(
                    controller: notesCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Notes (optional)'),
                    maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );

    if (saved == true && nameCtrl.text.trim().isNotEmpty && mounted) {
      final db = context.read<DatabaseHelper>();
      final exercise = Exercise(
        name: nameCtrl.text.trim(),
        muscleGroup: muscleGroup,
        equipment: equipment,
        difficulty: difficulty,
        isCustom: true,
        notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
      );
      await db.insertExercise(exercise);
      _loadExercises();
    }
  }
}
