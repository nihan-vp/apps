import 'package:flutter/material.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import 'package:focuson_interop/focuson_interop.dart';

class TasksScreen extends StatefulWidget {
  final FocusDatabase db;
  final String? prefillTitle;

  const TasksScreen({super.key, required this.db, this.prefillTitle});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _tabIndex = 0; // 0=Today, 1=Upcoming, 2=Overdue, 3=Completed, 4=All
  List<Task> _tasks = [];
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    if (widget.prefillTitle != null && widget.prefillTitle!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddEditTaskSheet(prefill: widget.prefillTitle);
      });
    }
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    List<Task> list;
    if (_searchQuery.trim().isNotEmpty) {
      list = await widget.db.taskRepo.searchTasks(_searchQuery);
    } else {
      switch (_tabIndex) {
        case 0:
          list = await widget.db.taskRepo.getTodayTasks();
          break;
        case 1:
          list = await widget.db.taskRepo.getUpcomingTasks();
          break;
        case 2:
          list = await widget.db.taskRepo.getOverdueTasks();
          break;
        case 3:
          list = await widget.db.taskRepo.getCompletedTasks();
          break;
        case 4:
        default:
          list = await widget.db.taskRepo.getAllTasks();
          break;
      }
    }

    if (mounted) {
      setState(() {
        _tasks = list;
        _isLoading = false;
      });
    }
  }

  void _showAddEditTaskSheet({Task? existing, String? prefill}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? prefill ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    final tagsCtrl = TextEditingController(text: existing?.tags.join(', ') ?? '');
    var priority = existing?.priority ?? FocusPriority.medium;
    var recurrence = existing?.recurrence ?? RecurrenceRule.none;
    DateTime? dueDate = existing?.dueDate ?? DateTime.now();

    FocusBottomSheet.show(
      context: context,
      title: existing == null ? 'New Task' : 'Edit Task',
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.lg, vertical: FocusSpacing.md),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FocusTextField(label: 'Task Title', hint: 'e.g. Study Algorithms Chapter 5', controller: titleCtrl, autofocus: true),
                  const SizedBox(height: FocusSpacing.sm),
                  FocusTextField(label: 'Description', hint: 'Optional context or details', controller: descCtrl, maxLines: 2),
                  const SizedBox(height: FocusSpacing.md),

                  const Text('Priority', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: FocusSpacing.xs),
                  Wrap(
                    spacing: FocusSpacing.sm,
                    children: FocusPriority.values.map((p) {
                      final isSelected = priority == p;
                      return ChoiceChip(
                        label: Text(p.label),
                        selected: isSelected,
                        onSelected: (_) => setSheetState(() => priority = p),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: FocusSpacing.md),

                  // Due Date
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: FocusColors.electricBlue),
                      const SizedBox(width: FocusSpacing.sm),
                      Text(
                        dueDate != null ? 'Due: ${FocusTimeUtils.formatReadableDate(dueDate!)}' : 'No Due Date',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const Spacer(),
                      FocusButton(
                        label: 'Change Date',
                        height: 32,
                        variant: FocusButtonVariant.secondary,
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: dueDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                          );
                          if (picked != null) {
                            setSheetState(() => dueDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: FocusSpacing.md),

                  // Recurrence
                  const Text('Repeat Schedule', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: FocusSpacing.xs),
                  DropdownButtonFormField<RecurrenceRule>(
                    value: recurrence,
                    dropdownColor: FocusColors.darkSurfaceHigh,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: FocusColors.darkSurfaceHigh,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(FocusSpacing.radiusMd)),
                    ),
                    items: RecurrenceRule.values.map((r) {
                      return DropdownMenuItem(value: r, child: Text(r.label));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setSheetState(() => recurrence = val);
                    },
                  ),
                  const SizedBox(height: FocusSpacing.md),

                  FocusTextField(label: 'Tags (comma separated)', hint: 'exam, math, project', controller: tagsCtrl),
                  const SizedBox(height: FocusSpacing.sm),
                  FocusTextField(label: 'Notes', hint: 'Additional references, URLs...', controller: notesCtrl, maxLines: 2),
                  const SizedBox(height: FocusSpacing.lg),

                  FocusButton(
                    label: existing == null ? 'Create Task' : 'Save Changes',
                    isFullWidth: true,
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;

                      final tags = tagsCtrl.text
                          .split(',')
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .toList();

                      final task = Task(
                        id: existing?.id,
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        priority: priority,
                        dueDate: dueDate,
                        recurrence: recurrence,
                        tags: tags,
                        notes: notesCtrl.text.trim(),
                        status: existing?.status ?? TaskStatus.notStarted,
                      );

                      if (existing == null) {
                        await widget.db.taskRepo.insertTask(task);
                      } else {
                        await widget.db.taskRepo.updateTask(task);
                      }

                      Navigator.of(ctx).pop();
                      _loadTasks();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
        backgroundColor: FocusColors.electricBlue,
        onPressed: () => _showAddEditTaskSheet(),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.lg, vertical: FocusSpacing.sm),
            child: FocusSearchBar(
              hint: 'Search tasks, tags, notes...',
              onChanged: (q) {
                setState(() => _searchQuery = q);
                _loadTasks();
              },
            ),
          ),

          // Tab chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.lg),
              children: ['Today', 'Upcoming', 'Overdue', 'Completed', 'All'].asMap().entries.map((entry) {
                final isSelected = _tabIndex == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: FocusSpacing.sm),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _tabIndex = entry.key);
                      _loadTasks();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: FocusSpacing.sm),

          // Task List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                    ? const FocusEmptyState(
                        icon: Icons.checklist_rtl,
                        title: 'No Tasks Found',
                        message: 'Enjoy your free time or tap below to plan your next priority.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.lg, vertical: FocusSpacing.sm),
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          final task = _tasks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: FocusSpacing.sm),
                            child: FocusTaskCard(
                              task: task,
                              onTap: () => _showAddEditTaskSheet(existing: task),
                              onToggleComplete: () async {
                                await widget.db.taskRepo.toggleTaskCompletion(task.id);
                                _loadTasks();
                              },
                              onStartFocus: () {
                                // Ecosystem cross-app integration: Launch Control focus session for this task!
                                EcosystemNavigator.navigateOrFallback(
                                  context,
                                  StartSessionContract(
                                    durationMinutes: 25,
                                    intention: task.title,
                                    linkedTaskId: task.id,
                                  ).toUri(),
                                  featureDescription: 'FocusON Control Session',
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
