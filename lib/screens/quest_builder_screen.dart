import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import '../models/models.dart';
import 'workout_logger_screen.dart';

/// Lists all quests and lets the user create/edit/delete them.
class QuestBuilderScreen extends StatefulWidget {
  const QuestBuilderScreen({super.key});

  @override
  State<QuestBuilderScreen> createState() => _QuestBuilderScreenState();
}

class _QuestBuilderScreenState extends State<QuestBuilderScreen> {
  List<Quest> _quests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    final db = context.read<DatabaseHelper>();
    final quests = await db.getQuests();
    if (mounted) setState(() { _quests = quests; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Quests')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openQuestForm(context),
        icon: const Icon(Icons.add),
        label: const Text('New Quest'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _quests.isEmpty
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_outlined, size: 64, color: theme.colorScheme.outline),
                    const SizedBox(height: 12),
                    Text('No quests yet', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Create your first workout quest!', style: theme.textTheme.bodySmall),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _loadQuests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _quests.length,
                    itemBuilder: (context, index) => _buildQuestTile(_quests[index], theme),
                  ),
                ),
    );
  }

  Widget _buildQuestTile(Quest quest, ThemeData theme) {
    return Dismissible(
      key: Key(quest.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Quest?'),
            content: Text('Are you sure you want to delete "${quest.title}"? This cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        final db = context.read<DatabaseHelper>();
        await db.deleteQuest(quest.id);
        _loadQuests();
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => WorkoutLoggerScreen(quest: quest)),
            ).then((_) => _loadQuests());
          },
          onLongPress: () => _openQuestForm(context, quest: quest),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(quest.isCompleted ? Icons.emoji_events : Icons.flag,
                    color: quest.isCompleted ? Colors.amber : theme.colorScheme.primary,
                    size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(quest.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
                  Text('${quest.completedSessions}/${quest.targetSessions}', style: theme.textTheme.bodySmall),
                ]),
                const SizedBox(height: 4),
                Text(quest.description, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: quest.progress.clamp(0.0, 1.0),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                Text('${quest.exercises.length} exercises • ${quest.isCompleted ? "Completed!" : "Active"}',
                  style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Open form to create or edit a quest
  Future<void> _openQuestForm(BuildContext context, {Quest? quest}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _QuestFormScreen(quest: quest)),
    );
    if (result == true) _loadQuests();
  }
}

/// Form screen for creating/editing a quest
class _QuestFormScreen extends StatefulWidget {
  final Quest? quest;
  const _QuestFormScreen({this.quest});

  @override
  State<_QuestFormScreen> createState() => _QuestFormScreenState();
}

class _QuestFormScreenState extends State<_QuestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _targetCtrl;
  List<_SelectedExercise> _selectedExercises = [];
  bool _saving = false;

  bool get _isEditing => widget.quest != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.quest?.title ?? '');
    _descCtrl = TextEditingController(text: widget.quest?.description ?? '');
    _targetCtrl = TextEditingController(text: widget.quest?.targetSessions.toString() ?? '5');

    if (_isEditing) {
      _selectedExercises = widget.quest!.exercises.map((qe) => _SelectedExercise(
        exercise: qe.exercise!,
        sets: qe.targetSets,
        reps: qe.targetReps,
        weight: qe.targetWeight,
      )).toList();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Quest' : 'New Quest'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            label: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Quest Title', hintText: 'e.g., Upper Body Blitz'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            // Description
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description', hintText: 'What is this quest about?'),
              maxLines: 2,
              validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
            ),
            const SizedBox(height: 12),
            // Target sessions
            TextFormField(
              controller: _targetCtrl,
              decoration: const InputDecoration(labelText: 'Target Sessions', hintText: 'How many sessions to complete?'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final n = int.tryParse(v);
                if (n == null || n < 1) return 'Enter a positive number';
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Exercises
            Row(
              children: [
                Text('Exercises', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  onPressed: _pickExercise,
                ),
              ],
            ),
            if (_selectedExercises.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('No exercises added yet. Tap "Add" to pick from the library.',
                  style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
              ),
            ..._selectedExercises.asMap().entries.map((entry) {
              final i = entry.key;
              final se = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(se.exercise.name),
                  subtitle: Text('${se.sets} sets × ${se.reps} reps${se.weight != null ? " @ ${se.weight}kg" : ""}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _selectedExercises.removeAt(i)),
                  ),
                ),
              );
            }),
            const SizedBox(height: 80), // space for FAB
          ],
        ),
      ),
    );
  }

  Future<void> _pickExercise() async {
    final db = context.read<DatabaseHelper>();
    final exercises = await db.getExercises();

    if (!mounted) return;

    final picked = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Pick an Exercise', style: Theme.of(ctx).textTheme.titleMedium),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: exercises.length,
                itemBuilder: (_, i) {
                  final e = exercises[i];
                  return ListTile(
                    title: Text(e.name),
                    subtitle: Text('${e.muscleGroup} • ${e.equipment} • ${e.difficulty}'),
                    onTap: () => Navigator.pop(ctx, e),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (picked == null || !mounted) return;

    // Ask for sets/reps
    final setsCtrl = TextEditingController(text: '3');
    final repsCtrl = TextEditingController(text: '10');
    final weightCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(picked.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: setsCtrl, decoration: const InputDecoration(labelText: 'Sets'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: repsCtrl, decoration: const InputDecoration(labelText: 'Reps'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: weightCtrl, decoration: const InputDecoration(labelText: 'Weight (optional)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _selectedExercises.add(_SelectedExercise(
          exercise: picked,
          sets: int.tryParse(setsCtrl.text) ?? 3,
          reps: int.tryParse(repsCtrl.text) ?? 10,
          weight: double.tryParse(weightCtrl.text),
        ));
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise to your quest')),
      );
      return;
    }

    setState(() => _saving = true);

    final db = context.read<DatabaseHelper>();
    final quest = Quest(
      id: widget.quest?.id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      targetSessions: int.parse(_targetCtrl.text.trim()),
      completedSessions: widget.quest?.completedSessions ?? 0,
      isActive: true,
    );

    quest.exercises = _selectedExercises.asMap().entries.map((entry) {
      return QuestExercise(
        questId: quest.id,
        exerciseId: entry.value.exercise.id,
        targetSets: entry.value.sets,
        targetReps: entry.value.reps,
        targetWeight: entry.value.weight,
        orderIndex: entry.key,
        exercise: entry.value.exercise,
      );
    }).toList();

    if (_isEditing) {
      await db.deleteQuest(quest.id); // Remove old exercises too
    }
    await db.insertQuest(quest);

    if (mounted) Navigator.pop(context, true);
  }
}

class _SelectedExercise {
  final Exercise exercise;
  final int sets;
  final int reps;
  final double? weight;

  _SelectedExercise({required this.exercise, required this.sets, required this.reps, this.weight});
}
