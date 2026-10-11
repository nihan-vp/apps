import 'package:flutter/material.dart';
import 'package:focuson_design_system/focuson_design_system.dart';

/// Mindful intention prompt shown before launching a designated app.
class IntentionDialog extends StatefulWidget {
  final String appName;
  final String packageName;
  final VoidCallback onProceed;

  const IntentionDialog({
    super.key,
    required this.appName,
    required this.packageName,
    required this.onProceed,
  });

  static Future<void> show(
    BuildContext context, {
    required String appName,
    required String packageName,
    required VoidCallback onProceed,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => IntentionDialog(
        appName: appName,
        packageName: packageName,
        onProceed: onProceed,
      ),
    );
  }

  @override
  State<IntentionDialog> createState() => _IntentionDialogState();
}

class _IntentionDialogState extends State<IntentionDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Opening ${widget.appName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Take a mindful pause. What is your intention for opening this application right now?',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: FocusSpacing.md),
          FocusTextField(
            hint: 'e.g. Check messages from family',
            controller: _controller,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        FocusButton(
          label: 'Stay Focused',
          variant: FocusButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        FocusButton(
          label: 'Continue',
          onPressed: () {
            Navigator.of(context).pop();
            widget.onProceed();
          },
        ),
      ],
    );
  }
}
