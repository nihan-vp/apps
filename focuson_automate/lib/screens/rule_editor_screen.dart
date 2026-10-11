import 'package:flutter/material.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import 'package:focuson_rules_engine/focuson_rules_engine.dart';

class RuleEditorScreen extends StatefulWidget {
  final FocusDatabase db;
  final AutomationRule? existingRule;

  const RuleEditorScreen({super.key, required this.db, this.existingRule});

  @override
  State<RuleEditorScreen> createState() => _RuleEditorScreenState();
}

class _RuleEditorScreenState extends State<RuleEditorScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late TriggerType _triggerType;
  late ConditionType _conditionType;
  late ActionType _actionType;
  int _priority = 10;
  bool _isEnabled = true;

  // Trigger configs
  String _timeTriggerVal = '09:00';
  String _profileTriggerVal = 'study';

  // Condition configs
  String _profileCondVal = 'study';
  int _batteryCondLevel = 20;

  // Action configs
  int _focusActionDuration = 25;
  String _actionIntention = 'Automated Focus Session';
  String _notificationTitle = 'Focus Alert';
  String _notificationMessage = 'Focus workflow engaged.';

  @override
  void initState() {
    super.initState();
    final rule = widget.existingRule;
    _titleCtrl = TextEditingController(text: rule?.title ?? '');
    _descCtrl = TextEditingController(text: rule?.description ?? '');
    _triggerType = rule?.triggerType ?? TriggerType.profileActivated;
    _conditionType = rule?.conditionType ?? ConditionType.activeProfile;
    _actionType = rule?.actionType ?? ActionType.startFocusSession;
    _priority = rule?.priority ?? 10;
    _isEnabled = rule?.isEnabled ?? true;

    if (rule != null) {
      if (rule.triggerConfig['time'] != null) _timeTriggerVal = rule.triggerConfig['time'];
      if (rule.triggerConfig['profile'] != null) _profileTriggerVal = rule.triggerConfig['profile'];
      if (rule.conditionConfig['profile'] != null) _profileCondVal = rule.conditionConfig['profile'];
      if (rule.actionConfig['duration'] != null) _focusActionDuration = rule.actionConfig['duration'];
      if (rule.actionConfig['intention'] != null) _actionIntention = rule.actionConfig['intention'];
      if (rule.actionConfig['title'] != null) _notificationTitle = rule.actionConfig['title'];
      if (rule.actionConfig['message'] != null) _notificationMessage = rule.actionConfig['message'];
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  AutomationRule _buildRuleDraft() {
    final triggerConfig = <String, dynamic>{};
    if (_triggerType == TriggerType.timeSchedule) triggerConfig['time'] = _timeTriggerVal;
    if (_triggerType == TriggerType.profileActivated) triggerConfig['profile'] = _profileTriggerVal;

    final conditionConfig = <String, dynamic>{};
    if (_conditionType == ConditionType.activeProfile) conditionConfig['profile'] = _profileCondVal;
    if (_conditionType == ConditionType.batteryLevel) conditionConfig['level'] = _batteryCondLevel;

    final actionConfig = <String, dynamic>{};
    if (_actionType == ActionType.startFocusSession) {
      actionConfig['duration'] = _focusActionDuration;
      actionConfig['intention'] = _actionIntention;
      actionConfig['preset'] = 'smart';
    } else if (_actionType == ActionType.showNotification) {
      actionConfig['title'] = _notificationTitle;
      actionConfig['message'] = _notificationMessage;
    }

    return AutomationRule(
      id: widget.existingRule?.id,
      title: _titleCtrl.text.trim().isEmpty ? 'Custom Workflow' : _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      isEnabled: _isEnabled,
      priority: _priority,
      triggerType: _triggerType,
      triggerConfig: triggerConfig,
      conditionType: _conditionType,
      conditionConfig: conditionConfig,
      actionType: _actionType,
      actionConfig: actionConfig,
    );
  }

  void _runDryRunTest() async {
    final rule = _buildRuleDraft();
    final engine = FocusRulesEngine();
    final ctx = RuleExecutionContext(
      currentProfile: ProfileType.fromString(_profileCondVal),
      batteryLevel: _batteryCondLevel,
    );

    final execution = await engine.executeRule(rule, ctx, isDryRun: true);
    await widget.db.automationRepo.recordExecution(execution);

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('🧪 Dry Run Simulation Result'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Conditions Passed: ${execution.conditionsPassed ? "YES ✅" : "NO ❌"}'),
              const SizedBox(height: 6),
              Text('Action Result: ${execution.actionResult}'),
              const SizedBox(height: 6),
              Text('Execution Time: ${execution.executionDurationMs} ms'),
            ],
          ),
          actions: [
            FocusButton(label: 'Close', onPressed: () => Navigator.of(ctx).pop()),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingRule == null ? 'Create Automation' : 'Edit Automation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.science_outlined),
            tooltip: 'Dry Run Test',
            onPressed: _runDryRunTest,
          ),
        ],
      ),
      body: ListView(
        padding: FocusSpacing.insetAllLg,
        children: [
          FocusTextField(label: 'Automation Name', hint: 'e.g. Study Mode Pomodoro', controller: _titleCtrl, autofocus: true),
          const SizedBox(height: FocusSpacing.sm),
          FocusTextField(label: 'Description', hint: 'Explain why and when this workflow runs', controller: _descCtrl),
          const SizedBox(height: FocusSpacing.lg),

          // WHEN CARD
          FocusCard(
            borderColor: FocusColors.electricBlue.withOpacity(0.5),
            padding: FocusSpacing.insetAllMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt, color: FocusColors.electricBlue, size: 20),
                    SizedBox(width: FocusSpacing.xs),
                    Text('WHEN (TRIGGER)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: FocusColors.electricBlue)),
                  ],
                ),
                const SizedBox(height: FocusSpacing.sm),
                DropdownButtonFormField<TriggerType>(
                  value: _triggerType,
                  dropdownColor: FocusColors.darkSurfaceHigh,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: FocusColors.darkSurfaceHigh,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(FocusSpacing.radiusMd)),
                  ),
                  items: TriggerType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _triggerType = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: FocusSpacing.md),

          // IF CARD
          FocusCard(
            borderColor: FocusColors.amberWarning.withOpacity(0.5),
            padding: FocusSpacing.insetAllMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.filter_alt_outlined, color: FocusColors.amberWarning, size: 20),
                    SizedBox(width: FocusSpacing.xs),
                    Text('IF (CONDITION)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: FocusColors.amberWarning)),
                  ],
                ),
                const SizedBox(height: FocusSpacing.sm),
                DropdownButtonFormField<ConditionType>(
                  value: _conditionType,
                  dropdownColor: FocusColors.darkSurfaceHigh,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: FocusColors.darkSurfaceHigh,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(FocusSpacing.radiusMd)),
                  ),
                  items: ConditionType.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _conditionType = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: FocusSpacing.md),

          // THEN CARD
          FocusCard(
            borderColor: FocusColors.emeraldGreen.withOpacity(0.5),
            padding: FocusSpacing.insetAllMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: FocusColors.emeraldGreen, size: 20),
                    SizedBox(width: FocusSpacing.xs),
                    Text('THEN (ACTION)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: FocusColors.emeraldGreen)),
                  ],
                ),
                const SizedBox(height: FocusSpacing.sm),
                DropdownButtonFormField<ActionType>(
                  value: _actionType,
                  dropdownColor: FocusColors.darkSurfaceHigh,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: FocusColors.darkSurfaceHigh,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(FocusSpacing.radiusMd)),
                  ),
                  items: ActionType.values.map((a) => DropdownMenuItem(value: a, child: Text(a.name))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _actionType = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: FocusSpacing.lg),

          // Priority & Enable Switch
          Text('Execution Priority: $_priority (Higher runs first)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Slider(
            value: _priority.toDouble(),
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: FocusColors.electricBlue,
            onChanged: (val) => setState(() => _priority = val.toInt()),
          ),

          SwitchListTile(
            title: const Text('Rule Enabled'),
            subtitle: const Text('Active workflows automatically evaluate in background.'),
            value: _isEnabled,
            activeColor: FocusColors.electricBlue,
            onChanged: (val) => setState(() => _isEnabled = val),
          ),
          const SizedBox(height: FocusSpacing.lg),

          FocusButton(
            label: widget.existingRule == null ? 'Save Automation' : 'Update Automation',
            isFullWidth: true,
            onPressed: () async {
              if (_titleCtrl.text.trim().isEmpty) return;
              final rule = _buildRuleDraft();
              if (widget.existingRule == null) {
                await widget.db.automationRepo.insertRule(rule);
              } else {
                await widget.db.automationRepo.updateRule(rule);
              }
              if (mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
