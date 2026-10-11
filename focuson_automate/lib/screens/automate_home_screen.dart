import 'package:flutter/material.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import 'package:focuson_rules_engine/focuson_rules_engine.dart';
import 'rule_editor_screen.dart';
import 'templates_screen.dart';
import 'execution_history_screen.dart';

class AutomateHomeScreen extends StatefulWidget {
  final FocusDatabase db;

  const AutomateHomeScreen({super.key, required this.db});

  @override
  State<AutomateHomeScreen> createState() => _AutomateHomeScreenState();
}

class _AutomateHomeScreenState extends State<AutomateHomeScreen> {
  late Future<List<AutomationRule>> _rulesFuture;
  final FocusRulesEngine _engine = FocusRulesEngine();

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  void _loadRules() {
    setState(() {
      _rulesFuture = widget.db.automationRepo.getAllRules();
    });
  }

  void _runRuleNow(AutomationRule rule) async {
    final ctx = RuleExecutionContext(
      currentProfile: ProfileType.study,
      batteryLevel: 85,
    );
    final exec = await _engine.executeRule(rule, ctx, isDryRun: false);
    await widget.db.automationRepo.recordExecution(exec);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            exec.conditionsPassed
                ? 'Executed "${rule.title}": ${exec.actionResult}'
                : 'Condition skipped for "${rule.title}"',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      _loadRules();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FocusON Automate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_books_outlined),
            tooltip: 'Templates',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TemplatesScreen(db: widget.db)),
              );
              _loadRules();
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ExecutionHistoryScreen(db: widget.db)),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<AutomationRule>>(
        future: _rulesFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final rules = snapshot.data ?? [];
          if (rules.isEmpty) {
            return Center(
              child: Padding(
                padding: FocusSpacing.insetAllXl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FocusEmptyState(
                      icon: Icons.alt_route,
                      title: 'No Workflows Defined',
                      message: 'Automate your focus sessions, restrictions, and habits with WHEN ➔ IF ➔ THEN deterministic triggers.',
                    ),
                    const SizedBox(height: FocusSpacing.lg),
                    Wrap(
                      spacing: FocusSpacing.md,
                      runSpacing: FocusSpacing.sm,
                      children: [
                        FocusButton(
                          label: 'Explore Templates',
                          variant: FocusButtonVariant.secondary,
                          icon: Icons.auto_fix_high,
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => TemplatesScreen(db: widget.db)),
                            );
                            _loadRules();
                          },
                        ),
                        FocusButton(
                          label: 'Create Custom Rule',
                          icon: Icons.add,
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => RuleEditorScreen(db: widget.db)),
                            );
                            _loadRules();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: FocusSpacing.insetAllMd,
            itemCount: rules.length,
            separatorBuilder: (_, __) => const SizedBox(height: FocusSpacing.md),
            itemBuilder: (ctx, idx) {
              final rule = rules[idx];
              return FocusCard(
                padding: FocusSpacing.insetAllMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rule.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                              if (rule.description.isNotEmpty)
                                Text(rule.description, style: const TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary)),
                            ],
                          ),
                        ),
                        Switch(
                          value: rule.isEnabled,
                          activeColor: FocusColors.electricBlue,
                          onChanged: (val) async {
                            await widget.db.automationRepo.toggleRule(rule.id, val);
                            _loadRules();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: FocusSpacing.sm),
                    // Rule Flow Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: FocusColors.darkSurfaceHigh,
                        borderRadius: BorderRadius.circular(FocusSpacing.radiusSm),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'WHEN: ${rule.triggerType.name}  ➔  IF: ${rule.conditionType.name}  ➔  THEN: ${rule.actionType.name}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: FocusColors.darkTextSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: FocusSpacing.sm),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: FocusColors.darkSurfaceHigh,
                            borderRadius: BorderRadius.circular(FocusSpacing.radiusSm),
                          ),
                          child: Text('Priority: ${rule.priority}', style: const TextStyle(fontSize: 11, color: FocusColors.darkTextSecondary)),
                        ),
                        const SizedBox(width: FocusSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: FocusColors.darkSurfaceHigh,
                            borderRadius: BorderRadius.circular(FocusSpacing.radiusSm),
                          ),
                          child: Text('Runs: ${rule.runCount}', style: const TextStyle(fontSize: 11, color: FocusColors.darkTextSecondary)),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.play_arrow, color: FocusColors.emeraldGreen),
                          tooltip: 'Run Trigger Now',
                          onPressed: () => _runRuleNow(rule),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Edit',
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => RuleEditorScreen(db: widget.db, existingRule: rule)),
                            );
                            _loadRules();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: FocusColors.coralDanger),
                          tooltip: 'Delete',
                          onPressed: () async {
                            await widget.db.automationRepo.deleteRule(rule.id);
                            _loadRules();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => RuleEditorScreen(db: widget.db)),
          );
          _loadRules();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
