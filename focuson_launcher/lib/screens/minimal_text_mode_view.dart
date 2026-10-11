import 'package:flutter/material.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import 'package:focuson_android_bridge/focuson_android_bridge.dart';
import '../widgets/intention_dialog.dart';

class MinimalTextModeView extends StatelessWidget {
  final List<InstalledAppInfo> apps;
  final Set<String> pinnedPackages;
  final Set<String> hiddenPackages;
  final Set<String> intentionPromptPackages;
  final Function(InstalledAppInfo) onTogglePin;
  final Function(InstalledAppInfo) onHideApp;

  const MinimalTextModeView({
    super.key,
    required this.apps,
    required this.pinnedPackages,
    required this.hiddenPackages,
    required this.intentionPromptPackages,
    required this.onTogglePin,
    required this.onHideApp,
  });

  void _handleAppLaunch(BuildContext context, InstalledAppInfo app) {
    if (intentionPromptPackages.contains(app.packageName)) {
      IntentionDialog.show(
        context,
        appName: app.appName,
        packageName: app.packageName,
        onProceed: () => FocusLauncherBridge.launchApp(app.packageName),
      );
    } else {
      FocusLauncherBridge.launchApp(app.packageName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final visibleApps = apps.where((a) => !hiddenPackages.contains(a.packageName)).toList();

    // Sort alphabetically
    visibleApps.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.xl, vertical: FocusSpacing.md),
      itemCount: visibleApps.length,
      itemBuilder: (context, index) {
        final app = visibleApps[index];
        final isPinned = pinnedPackages.contains(app.packageName);
        final isEcosystem = app.packageName.startsWith('com.focuson.');

        // Group letters
        final currentLetter = app.appName.isNotEmpty ? app.appName[0].toUpperCase() : '';
        final prevLetter = index > 0 && visibleApps[index - 1].appName.isNotEmpty
            ? visibleApps[index - 1].appName[0].toUpperCase()
            : '';
        final showLetterHeader = currentLetter != prevLetter;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLetterHeader) ...[
              Padding(
                padding: const EdgeInsets.only(top: FocusSpacing.lg, bottom: FocusSpacing.xs),
                child: Text(
                  currentLetter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: FocusColors.electricBlue.withOpacity(0.8),
                  ),
                ),
              ),
            ],
            InkWell(
              onTap: () => _handleAppLaunch(context, app),
              onLongPress: () => _showAppMenu(context, app),
              borderRadius: BorderRadius.circular(FocusSpacing.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: FocusSpacing.sm),
                child: Row(
                  children: [
                    if (isPinned)
                      const Padding(
                        padding: EdgeInsets.only(right: FocusSpacing.sm),
                        child: Icon(Icons.push_pin, size: 14, color: FocusColors.electricBlue),
                      ),
                    Text(
                      app.appName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isPinned ? FontWeight.w700 : FontWeight.w400,
                        color: isEcosystem
                            ? FocusColors.electricCyan
                            : (isDark ? FocusColors.darkTextPrimary : FocusColors.lightTextPrimary),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    if (intentionPromptPackages.contains(app.packageName))
                      const Text(
                        'intent prompt',
                        style: TextStyle(fontSize: 10, color: FocusColors.amberWarning),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAppMenu(BuildContext context, InstalledAppInfo app) {
    final isPinned = pinnedPackages.contains(app.packageName);
    showModalBottomSheet(
      context: context,
      backgroundColor: FocusColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(FocusSpacing.radiusXl)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(app.appName, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(app.packageName, style: const TextStyle(fontSize: 12, color: FocusColors.darkTextMuted)),
            ),
            const Divider(),
            ListTile(
              leading: Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin),
              title: Text(isPinned ? 'Unpin' : 'Pin to Top'),
              onTap: () {
                Navigator.of(ctx).pop();
                onTogglePin(app);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Hide from Home Screen'),
              subtitle: const Text('Removes from list without uninstalling', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.of(ctx).pop();
                onHideApp(app);
              },
            ),
          ],
        ),
      ),
    );
  }
}
