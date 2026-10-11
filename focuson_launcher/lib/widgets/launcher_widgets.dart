import 'package:flutter/material.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import 'package:focuson_interop/focuson_interop.dart';

class PrioritiesWidget extends StatelessWidget {
  final List<Task> todayTasks;
  final VoidCallback onRefresh;
  final FocusDatabase db;

  const PrioritiesWidget({
    super.key,
    required this.todayTasks,
    required this.onRefresh,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FocusCard(
      padding: FocusSpacing.insetAllMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: FocusColors.emeraldGreen, size: 18),
              const SizedBox(width: FocusSpacing.sm),
              const Text(
                'Today\'s Priorities',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => EcosystemNavigator.navigateOrFallback(
                  context,
                  Uri.parse('focuson-planner://tasks'),
                  featureDescription: 'Planner Tasks',
                ),
                child: const Text(
                  'Open Planner',
                  style: TextStyle(fontSize: 11, color: FocusColors.electricBlue, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: FocusSpacing.sm),
          if (todayTasks.isEmpty)
            Text(
              'No pending tasks for today. You are all caught up!',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? FocusColors.darkTextMuted : FocusColors.lightTextMuted,
              ),
            )
          else
            Column(
              children: todayTasks.take(2).map((task) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: FocusSpacing.xs),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () async {
                          await db.taskRepo.toggleTaskCompletion(task.id);
                          onRefresh();
                        },
                        child: const Icon(Icons.circle_outlined, size: 16, color: FocusColors.emeraldGreen),
                      ),
                      const SizedBox(width: FocusSpacing.sm),
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class FocusTimerSummaryWidget extends StatelessWidget {
  final FocusSession? activeSession;

  const FocusTimerSummaryWidget({
    super.key,
    this.activeSession,
  });

  @override
  Widget build(BuildContext context) {
    final hasActive = activeSession != null && activeSession!.state == SessionState.running;

    return FocusCard(
      padding: FocusSpacing.insetAllMd,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasActive ? FocusColors.amberWarning.withOpacity(0.15) : FocusColors.electricBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(FocusSpacing.radiusSm),
            ),
            child: Icon(
              hasActive ? Icons.timer : Icons.play_arrow,
              color: hasActive ? FocusColors.amberWarning : FocusColors.electricBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: FocusSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasActive ? 'Focus Session Active' : 'Start Focus Session',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                Text(
                  hasActive
                      ? 'Target: ${activeSession!.targetDurationMinutes} min (${activeSession!.intention})'
                      : 'Lock distractions with FocusON Control',
                  style: const TextStyle(fontSize: 11, color: FocusColors.darkTextMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          FocusButton(
            label: hasActive ? 'View' : 'Start',
            height: 32,
            variant: hasActive ? FocusButtonVariant.secondary : FocusButtonVariant.primary,
            onPressed: () {
              EcosystemNavigator.navigateOrFallback(
                context,
                StartSessionContract(durationMinutes: 25, intention: 'Quick Focus').toUri(),
                featureDescription: 'FocusON Control Session',
              );
            },
          ),
        ],
      ),
    );
  }
}

class QuickTaskEntryWidget extends StatefulWidget {
  final FocusDatabase db;
  final VoidCallback onTaskAdded;

  const QuickTaskEntryWidget({
    super.key,
    required this.db,
    required this.onTaskAdded,
  });

  @override
  State<QuickTaskEntryWidget> createState() => _QuickTaskEntryWidgetState();
}

class _QuickTaskEntryWidgetState extends State<QuickTaskEntryWidget> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    final task = Task(
      title: title,
      priority: FocusPriority.medium,
      dueDate: DateTime.now(),
    );
    await widget.db.taskRepo.insertTask(task);
    _controller.clear();
    widget.onTaskAdded();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: FocusColors.darkSurfaceHigh,
        borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
        border: Border.all(color: FocusColors.darkBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.add_task, size: 20, color: FocusColors.electricBlue),
          const SizedBox(width: FocusSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(color: FocusColors.darkTextPrimary, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Quick task: e.g. Review chapter 4',
                hintStyle: TextStyle(color: FocusColors.darkTextMuted, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_upward, size: 18, color: FocusColors.electricBlue),
            onPressed: _submit,
            tooltip: 'Add Priority',
          ),
        ],
      ),
    );
  }
}
