import 'package:flutter/material.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import '../services/ai_service.dart';
import 'provider_settings_screen.dart';

class TaskBreakdownScreen extends StatefulWidget {
  final AIService aiService;
  final FocusDatabase db;

  const TaskBreakdownScreen({super.key, required this.aiService, required this.db});

  @override
  State<TaskBreakdownScreen> createState() => _TaskBreakdownScreenState();
}

class _TaskBreakdownScreenState extends State<TaskBreakdownScreen> {
  final TextEditingController _taskCtrl = TextEditingController(text: 'Write research paper on distributed systems');
  bool _isLoading = false;
  List<Subtask> _subtasks = [];
  String? _error;

  @override
  void dispose() {
    _taskCtrl.dispose();
    super.dispose();
  }

  void _runBreakdown() async {
    final title = _taskCtrl.text.trim();
    if (title.isEmpty) return;

    if (!widget.aiService.isConfigured) {
      setState(() => _error = 'AI Provider is not configured. Configure a local or cloud provider to generate breakdowns.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final task = Task(title: title);
      final results = await widget.aiService.breakdownTask(task);
      setState(() {
        _subtasks = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _saveToPlanner() async {
    if (_subtasks.isEmpty) return;
    final parentTask = Task(
      title: _taskCtrl.text.trim(),
      priority: FocusPriority.high,
    );
    await widget.db.taskRepo.insertTask(parentTask);

    for (final st in _subtasks) {
      await widget.db.taskRepo.insertSubtask(Subtask(
        taskId: parentTask.id,
        title: st.title,
        sortOrder: st.sortOrder,
      ));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created task "${parentTask.title}" with ${_subtasks.length} subtasks in Planner!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Task Breakdown'),
      ),
      body: ListView(
        padding: FocusSpacing.insetAllLg,
        children: [
          FocusTextField(
            label: 'Goal or Complex Task',
            hint: 'e.g. Prepare for Biology Final Exam',
            controller: _taskCtrl,
          ),
          const SizedBox(height: FocusSpacing.md),
          FocusButton(
            label: _isLoading ? 'Generating Breakdown...' : 'Deconstruct Task into Action Steps',
            isFullWidth: true,
            icon: Icons.account_tree_outlined,
            onPressed: _isLoading ? null : _runBreakdown,
          ),
          const SizedBox(height: FocusSpacing.lg),

          if (_error != null)
            FocusCard(
              borderColor: FocusColors.coralDanger.withOpacity(0.5),
              padding: FocusSpacing.insetAllMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber, color: FocusColors.coralDanger, size: 20),
                      SizedBox(width: FocusSpacing.xs),
                      Text('Provider Not Configured', style: TextStyle(fontWeight: FontWeight.bold, color: FocusColors.coralDanger)),
                    ],
                  ),
                  const SizedBox(height: FocusSpacing.xs),
                  Text(_error!, style: const TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary)),
                  const SizedBox(height: FocusSpacing.sm),
                  FocusButton(
                    label: 'Configure AI Provider',
                    variant: FocusButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ProviderSettingsScreen(aiService: widget.aiService)),
                    ),
                  ),
                ],
              ),
            ),

          if (_subtasks.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Actionable Steps (${_subtasks.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                FocusButton(
                  label: 'Save to Planner',
                  height: 32,
                  variant: FocusButtonVariant.primary,
                  onPressed: _saveToPlanner,
                ),
              ],
            ),
            const SizedBox(height: FocusSpacing.sm),
            ..._subtasks.map((st) => Padding(
              padding: const EdgeInsets.only(bottom: FocusSpacing.sm),
              child: FocusCard(
                padding: FocusSpacing.insetAllMd,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: FocusColors.electricBlue.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${st.sortOrder + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FocusColors.electricBlue)),
                      ),
                    ),
                    const SizedBox(width: FocusSpacing.md),
                    Expanded(
                      child: Text(st.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }
}
