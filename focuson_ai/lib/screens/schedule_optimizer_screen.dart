import 'package:flutter/material.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import 'package:focuson_ai_core/focuson_ai_core.dart';
import '../services/ai_service.dart';
import 'provider_settings_screen.dart';

class ScheduleOptimizerScreen extends StatefulWidget {
  final AIService aiService;
  final FocusDatabase db;

  const ScheduleOptimizerScreen({super.key, required this.aiService, required this.db});

  @override
  State<ScheduleOptimizerScreen> createState() => _ScheduleOptimizerScreenState();
}

class _ScheduleOptimizerScreenState extends State<ScheduleOptimizerScreen> {
  int _availableHours = 4;
  bool _isLoading = false;
  List<DailyPlanBlock> _scheduleBlocks = [];
  String? _error;

  void _runOptimizer() async {
    if (!widget.aiService.isConfigured) {
      setState(() => _error = 'AI Provider is not configured. Please choose a provider in Settings.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tasks = await widget.db.taskRepo.getTodayTasks();
      final sampleTasks = tasks.isNotEmpty
          ? tasks
          : [
              Task(title: 'Review Machine Learning Chapter 4', priority: FocusPriority.urgent),
              Task(title: 'Fix Database Indexing Bug', priority: FocusPriority.high),
              Task(title: 'Write Weekly Progress Update', priority: FocusPriority.medium),
              Task(title: 'Inbox Zero & Clean Workspace', priority: FocusPriority.low),
            ];

      final blocks = await widget.aiService.generateDailyPlan(sampleTasks, _availableHours);
      setState(() {
        _scheduleBlocks = blocks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Optimizer'),
      ),
      body: ListView(
        padding: FocusSpacing.insetAllLg,
        children: [
          FocusCard(
            padding: FocusSpacing.insetAllMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available Focus Time Today', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: FocusSpacing.xs),
                Text('$_availableHours Hours', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: FocusColors.electricBlue)),
                Slider(
                  value: _availableHours.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: FocusColors.electricBlue,
                  onChanged: (val) => setState(() => _availableHours = val.toInt()),
                ),
              ],
            ),
          ),
          const SizedBox(height: FocusSpacing.md),

          FocusButton(
            label: _isLoading ? 'Optimizing Time Blocks...' : 'Generate Optimal Schedule',
            isFullWidth: true,
            icon: Icons.auto_awesome,
            onPressed: _isLoading ? null : _runOptimizer,
          ),
          const SizedBox(height: FocusSpacing.lg),

          if (_error != null)
            FocusCard(
              borderColor: FocusColors.coralDanger.withOpacity(0.5),
              padding: FocusSpacing.insetAllMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Provider Not Configured', style: TextStyle(fontWeight: FontWeight.bold, color: FocusColors.coralDanger)),
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

          if (_scheduleBlocks.isNotEmpty) ...[
            const Text('Generated Time-Block Plan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: FocusSpacing.sm),
            ..._scheduleBlocks.map((block) => Padding(
              padding: const EdgeInsets.only(bottom: FocusSpacing.sm),
              child: FocusCard(
                padding: FocusSpacing.insetAllMd,
                borderColor: FocusColors.electricBlue.withOpacity(0.3),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: FocusColors.electricBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(FocusSpacing.radiusSm),
                      ),
                      child: Text(
                        block.timeWindow,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: FocusColors.electricBlue),
                      ),
                    ),
                    const SizedBox(width: FocusSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(block.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text('${block.allocatedMinutes} min focus block', style: const TextStyle(fontSize: 11, color: FocusColors.darkTextSecondary)),
                        ],
                      ),
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
