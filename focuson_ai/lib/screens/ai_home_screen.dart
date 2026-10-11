import 'package:flutter/material.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import '../services/ai_service.dart';
import 'provider_settings_screen.dart';
import 'task_breakdown_screen.dart';
import 'schedule_optimizer_screen.dart';
import 'syllabus_generator_screen.dart';
import 'distraction_insights_screen.dart';

class AIHomeScreen extends StatefulWidget {
  final FocusDatabase db;
  final AIService aiService;

  const AIHomeScreen({super.key, required this.db, required this.aiService});

  @override
  State<AIHomeScreen> createState() => _AIHomeScreenState();
}

class _AIHomeScreenState extends State<AIHomeScreen> {
  final TextEditingController _promptCtrl = TextEditingController();
  bool _isProcessing = false;
  Task? _parsedTaskDraft;
  AutomationRule? _suggestedRule;

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  void _processPrompt() async {
    final text = _promptCtrl.text.trim();
    if (text.isEmpty) return;

    if (!widget.aiService.isConfigured) {
      _showUnconfiguredDialog();
      return;
    }

    setState(() {
      _isProcessing = true;
      _parsedTaskDraft = null;
      _suggestedRule = null;
    });

    try {
      if (text.toLowerCase().contains('rule') ||
          text.toLowerCase().contains('automate') ||
          text.toLowerCase().contains('when')) {
        final rule = await widget.aiService.generateWorkflow(text);
        setState(() => _suggestedRule = rule);
      } else {
        final task = await widget.aiService.parseTask(text);
        setState(() => _parsedTaskDraft = task);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Processing error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showUnconfiguredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: FocusColors.amberWarning),
            SizedBox(width: 8),
            Text('Provider Not Configured'),
          ],
        ),
        content: const Text(
          'FocusON AI adheres to strict honest disclosures and never fabricates mock AI answers. Please select a provider (Local Deterministic, Ollama LAN, or Cloud API) in Settings.',
        ),
        actions: [
          FocusButton(
            label: 'Open Settings',
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProviderSettingsScreen(aiService: widget.aiService)),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getProviderLabel() {
    switch (widget.aiService.mode) {
      case AIProviderMode.unconfigured:
        return 'Not Configured';
      case AIProviderMode.localDeterministic:
        return 'Local Offline';
      case AIProviderMode.ollamaLocal:
        return 'Ollama LAN';
      case AIProviderMode.cloudOpenAI:
        return 'Cloud API';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.aiService,
      builder: (ctx, _) {
        final isConfigured = widget.aiService.isConfigured;

        return Scaffold(
          appBar: AppBar(
            title: const Text('FocusON AI'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: FocusSpacing.md),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ProviderSettingsScreen(aiService: widget.aiService)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isConfigured
                          ? FocusColors.emeraldGreen.withOpacity(0.15)
                          : FocusColors.coralDanger.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(FocusSpacing.radiusPill),
                      border: Border.all(
                        color: isConfigured ? FocusColors.emeraldGreen : FocusColors.coralDanger,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isConfigured ? Icons.check_circle : Icons.warning_amber,
                          size: 14,
                          color: isConfigured ? FocusColors.emeraldGreen : FocusColors.coralDanger,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getProviderLabel(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isConfigured ? FocusColors.emeraldGreen : FocusColors.coralDanger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: FocusSpacing.insetAllLg,
            children: [
              // Natural Language Quick Input
              FocusCard(
                padding: FocusSpacing.insetAllMd,
                borderColor: FocusColors.lavenderPurple.withOpacity(0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: FocusColors.lavenderPurple, size: 20),
                        SizedBox(width: FocusSpacing.xs),
                        Text('Natural Language Assistant', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: FocusSpacing.sm),
                    FocusTextField(
                      hint: 'e.g. Schedule calculus review tomorrow 4pm urgent #math',
                      controller: _promptCtrl,
                      maxLines: 2,
                    ),
                    const SizedBox(height: FocusSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FocusButton(
                        label: _isProcessing ? 'Processing...' : 'Process Query',
                        icon: Icons.send,
                        height: 36,
                        onPressed: _isProcessing ? null : _processPrompt,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FocusSpacing.md),

              // Parsed Task Draft Banner
              if (_parsedTaskDraft != null) ...[
                FocusCard(
                  borderColor: FocusColors.emeraldGreen,
                  padding: FocusSpacing.insetAllMd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Parsed Structured Task', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: FocusColors.emeraldGreen)),
                      const SizedBox(height: FocusSpacing.xs),
                      Text('Title: ${_parsedTaskDraft!.title}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      Text('Priority: ${_parsedTaskDraft!.priority.name} • Due: ${_parsedTaskDraft!.dueDate?.toLocal().toString().substring(0, 16) ?? "None"}',
                          style: const TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary)),
                      const SizedBox(height: FocusSpacing.sm),
                      FocusButton(
                        label: 'Save into FocusON Planner',
                        height: 32,
                        onPressed: () async {
                          await widget.db.taskRepo.insertTask(_parsedTaskDraft!);
                          setState(() => _parsedTaskDraft = null);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Task added to FocusON Planner!')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: FocusSpacing.md),
              ],

              // Suggested Rule Banner
              if (_suggestedRule != null) ...[
                FocusCard(
                  borderColor: FocusColors.electricBlue,
                  padding: FocusSpacing.insetAllMd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Suggested Automation Rule', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: FocusColors.electricBlue)),
                      const SizedBox(height: FocusSpacing.xs),
                      Text(_suggestedRule!.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(_suggestedRule!.description, style: const TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary)),
                      const SizedBox(height: FocusSpacing.sm),
                      FocusButton(
                        label: 'Save into FocusON Automate',
                        height: 32,
                        onPressed: () async {
                          await widget.db.automationRepo.insertRule(_suggestedRule!);
                          setState(() => _suggestedRule = null);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Automation rule imported into FocusON Automate!')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: FocusSpacing.md),
              ],

              const Text('Intelligence Capabilities', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: FocusSpacing.sm),

              _buildToolTile(
                icon: Icons.account_tree_outlined,
                color: FocusColors.electricBlue,
                title: 'Task Breakdown',
                subtitle: 'Deconstruct complex milestones into concrete micro-actions',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => TaskBreakdownScreen(aiService: widget.aiService, db: widget.db)),
                ),
              ),
              const SizedBox(height: FocusSpacing.sm),

              _buildToolTile(
                icon: Icons.view_timeline_outlined,
                color: FocusColors.emeraldGreen,
                title: 'Daily Schedule Optimizer',
                subtitle: 'Distribute prioritized tasks into realistic daily focus blocks',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ScheduleOptimizerScreen(aiService: widget.aiService, db: widget.db)),
                ),
              ),
              const SizedBox(height: FocusSpacing.sm),

              _buildToolTile(
                icon: Icons.school_outlined,
                color: FocusColors.amberWarning,
                title: 'Study Syllabus Generator',
                subtitle: 'Formulate a spaced revision roadmap leading up to exams',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SyllabusGeneratorScreen(aiService: widget.aiService, db: widget.db)),
                ),
              ),
              const SizedBox(height: FocusSpacing.sm),

              _buildToolTile(
                icon: Icons.insights_outlined,
                color: FocusColors.lavenderPurple,
                title: 'Distraction & Usage Insights',
                subtitle: 'Constructive analysis of screen time patterns without shaming',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => DistractionInsightsScreen(aiService: widget.aiService, db: widget.db)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return FocusCard(
      padding: FocusSpacing.insetAllMd,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(FocusSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: FocusSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: FocusColors.darkTextMuted),
        ],
      ),
    );
  }
}
