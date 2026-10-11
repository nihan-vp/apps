import 'package:flutter/material.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import 'package:focuson_rules_engine/focuson_rules_engine.dart';

class TemplatesScreen extends StatelessWidget {
  final FocusDatabase db;

  const TemplatesScreen({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    final templates = AutomationTemplates.builtInTemplates;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Automation Templates'),
      ),
      body: ListView.separated(
        padding: FocusSpacing.insetAllMd,
        itemCount: templates.length,
        separatorBuilder: (_, __) => const SizedBox(height: FocusSpacing.md),
        itemBuilder: (ctx, idx) {
          final t = templates[idx];
          return FocusCard(
            padding: FocusSpacing.insetAllMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(FocusSpacing.sm),
                      decoration: BoxDecoration(
                        color: FocusColors.electricBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
                      ),
                      child: const Icon(Icons.auto_fix_high, color: FocusColors.electricBlue, size: 20),
                    ),
                    const SizedBox(width: FocusSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          Text(t.description, style: const TextStyle(fontSize: 13, color: FocusColors.darkTextSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FocusSpacing.md),
                Container(
                  padding: FocusSpacing.insetAllSm,
                  decoration: BoxDecoration(
                    color: FocusColors.darkSurfaceHigh,
                    borderRadius: BorderRadius.circular(FocusSpacing.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Text('WHEN ${t.triggerType.name}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FocusColors.electricBlue)),
                      const Text(' ➔ ', style: TextStyle(fontSize: 11, color: FocusColors.darkTextSecondary)),
                      Text('IF ${t.conditionType.name}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FocusColors.amberWarning)),
                      const Text(' ➔ ', style: TextStyle(fontSize: 11, color: FocusColors.darkTextSecondary)),
                      Text('THEN ${t.actionType.name}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FocusColors.emeraldGreen)),
                    ],
                  ),
                ),
                const SizedBox(height: FocusSpacing.md),
                FocusButton(
                  label: 'Import Template',
                  isFullWidth: true,
                  variant: FocusButtonVariant.secondary,
                  onPressed: () async {
                    await db.automationRepo.insertRule(t);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Imported "${t.title}" into active automations!'),
                          duration: const Duration(milliseconds: 800),
                        ),
                      );
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
