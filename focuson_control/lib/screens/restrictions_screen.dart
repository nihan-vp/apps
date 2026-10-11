import 'package:flutter/material.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import 'package:focuson_android_bridge/focuson_android_bridge.dart';

class RestrictionsScreen extends StatefulWidget {
  final FocusDatabase db;

  const RestrictionsScreen({super.key, required this.db});

  @override
  State<RestrictionsScreen> createState() => _RestrictionsScreenState();
}

class _RestrictionsScreenState extends State<RestrictionsScreen> {
  List<RestrictionRule> _rules = [];
  bool _isOverlayPermitted = false;

  @override
  void initState() {
    super.initState();
    _loadRules();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final permitted = await FocusRestrictionsBridge.isOverlayPermitted();
    if (mounted) setState(() => _isOverlayPermitted = permitted);
  }

  Future<void> _loadRules() async {
    final rules = await widget.db.controlRepo.getAllRestrictionRules();
    if (mounted) setState(() => _rules = rules);
  }

  void _showAddEditRuleDialog([RestrictionRule? existing]) {
    final nameCtrl = TextEditingController(text: existing?.appName ?? '');
    final pkgCtrl = TextEditingController(text: existing?.packageName ?? '');
    var preset = existing?.preset ?? RestrictionPreset.smart;
    var dailyLimit = existing?.dailyLimitMinutes ?? 45;
    var warningMin = existing?.warningThresholdMinutes ?? 10;
    var isCooldown = existing?.isCooldownEnabled ?? true;
    var cooldownMin = existing?.cooldownMinutes ?? 15;
    var isStrict = existing?.isStrictEnforced ?? false;

    FocusBottomSheet.show(
      context: context,
      title: existing == null ? 'New App Restriction' : 'Edit Restriction',
      child: StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.lg, vertical: FocusSpacing.md),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FocusTextField(label: 'App Name', hint: 'e.g. YouTube', controller: nameCtrl),
                  const SizedBox(height: FocusSpacing.sm),
                  FocusTextField(label: 'Package Name', hint: 'e.g. com.google.android.youtube', controller: pkgCtrl),
                  const SizedBox(height: FocusSpacing.md),

                  const Text('Restriction Preset', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: FocusSpacing.xs),
                  DropdownButtonFormField<RestrictionPreset>(
                    value: preset,
                    dropdownColor: FocusColors.darkSurfaceHigh,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: FocusColors.darkSurfaceHigh,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(FocusSpacing.radiusMd)),
                    ),
                    items: RestrictionPreset.values.map((p) {
                      return DropdownMenuItem(value: p, child: Text(p.displayName));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => preset = val);
                    },
                  ),
                  const SizedBox(height: FocusSpacing.md),

                  Text('Daily Time Limit: $dailyLimit minutes', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Slider(
                    value: dailyLimit.toDouble(),
                    min: 5,
                    max: 180,
                    divisions: 35,
                    activeColor: FocusColors.electricBlue,
                    onChanged: (val) => setDialogState(() => dailyLimit = val.toInt()),
                  ),

                  SwitchListTile(
                    title: const Text('Mindful Cooldown Periods'),
                    subtitle: const Text('Enforce a temporary pause between app sessions.'),
                    value: isCooldown,
                    activeColor: FocusColors.electricBlue,
                    onChanged: (val) => setDialogState(() => isCooldown = val),
                  ),

                  SwitchListTile(
                    title: const Text('Strict Enforcement Overlay'),
                    subtitle: const Text('Display full-screen blocking overlay when limit expires.'),
                    value: isStrict,
                    activeColor: FocusColors.coralDanger,
                    onChanged: (val) => setDialogState(() => isStrict = val),
                  ),

                  const SizedBox(height: FocusSpacing.lg),
                  FocusButton(
                    label: existing == null ? 'Create Restriction' : 'Save Changes',
                    isFullWidth: true,
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty || pkgCtrl.text.trim().isEmpty) return;

                      final rule = RestrictionRule(
                        id: existing?.id,
                        appName: nameCtrl.text.trim(),
                        packageName: pkgCtrl.text.trim(),
                        preset: preset,
                        dailyLimitMinutes: dailyLimit,
                        warningThresholdMinutes: warningMin,
                        isCooldownEnabled: isCooldown,
                        cooldownMinutes: cooldownMin,
                        isStrictEnforced: isStrict,
                      );

                      if (existing == null) {
                        await widget.db.controlRepo.insertRestrictionRule(rule);
                      } else {
                        await widget.db.controlRepo.updateRestrictionRule(rule);
                      }

                      Navigator.of(ctx).pop();
                      _loadRules();
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
        label: const Text('Add Limit'),
        backgroundColor: FocusColors.electricBlue,
        onPressed: () => _showAddEditRuleDialog(),
      ),
      body: ListView(
        padding: FocusSpacing.insetAllLg,
        children: [
          // Overlay Permission Notice
          if (!_isOverlayPermitted)
            FocusCard(
              backgroundColor: FocusColors.amberWarning.withOpacity(0.12),
              borderColor: FocusColors.amberWarning.withOpacity(0.3),
              padding: FocusSpacing.insetAllMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.layers_outlined, color: FocusColors.amberWarning, size: 20),
                      SizedBox(width: FocusSpacing.sm),
                      Text('Overlay Permission Recommended', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: FocusColors.amberWarning)),
                    ],
                  ),
                  const SizedBox(height: FocusSpacing.xs),
                  const Text(
                    'To display intention prompts and cooldown timers directly over restricted applications, grant the "Display Over Other Apps" capability.',
                    style: TextStyle(fontSize: 12, height: 1.35),
                  ),
                  const SizedBox(height: FocusSpacing.sm),
                  FocusButton(
                    label: 'Grant Overlay Access',
                    height: 32,
                    variant: FocusButtonVariant.primary,
                    onPressed: () async {
                      await FocusRestrictionsBridge.openOverlaySettings();
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: FocusSpacing.md),

          // Honest Enforcement Disclosure
          const FocusCard(
            padding: FocusSpacing.insetAllMd,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: FocusColors.electricBlue, size: 20),
                SizedBox(width: FocusSpacing.sm),
                Expanded(
                  child: Text(
                    'Android security architecture prohibits arbitrary background termination. FocusON uses non-intrusive full-screen overlays and timer warnings rather than silently breaking OS interfaces or emergency access.',
                    style: TextStyle(fontSize: 12, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: FocusSpacing.lg),

          const FocusSectionHeader(title: 'CONFIGURED APP RULES'),
          if (_rules.isEmpty)
            const FocusEmptyState(
              icon: Icons.shield_outlined,
              title: 'No Restrictions Configured',
              message: 'Tap the button below to set healthy daily limits on distracting apps.',
            )
          else
            ..._rules.map((rule) {
              return Padding(
                padding: const EdgeInsets.only(bottom: FocusSpacing.sm),
                child: FocusCard(
                  padding: FocusSpacing.insetAllMd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: rule.isPaused ? FocusColors.darkBorder : FocusColors.coralDanger.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(FocusSpacing.radiusSm),
                            ),
                            child: Icon(
                              Icons.block,
                              size: 16,
                              color: rule.isPaused ? FocusColors.darkTextMuted : FocusColors.coralDanger,
                            ),
                          ),
                          const SizedBox(width: FocusSpacing.sm),
                          Expanded(
                            child: Text(
                              rule.appName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ),
                          IconButton(
                            icon: Icon(rule.isPaused ? Icons.play_arrow : Icons.pause, size: 20),
                            tooltip: rule.isPaused ? 'Resume Rule' : 'Pause Rule',
                            onPressed: () async {
                              await widget.db.controlRepo.updateRestrictionRule(
                                rule.copyWith(isPaused: !rule.isPaused),
                              );
                              _loadRules();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: FocusColors.coralDanger),
                            tooltip: 'Delete Rule',
                            onPressed: () async {
                              await widget.db.controlRepo.deleteRestrictionRule(rule.id);
                              _loadRules();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: FocusSpacing.xs),
                      Text(
                        'Preset: ${rule.preset.displayName} • ${rule.dailyLimitMinutes}m Daily Limit',
                        style: const TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary),
                      ),
                      if (rule.isCooldownEnabled)
                        Text(
                          'Mindful Cooldown: ${rule.cooldownMinutes}m between reopenings',
                          style: const TextStyle(fontSize: 11, color: FocusColors.emeraldGreen),
                        ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
