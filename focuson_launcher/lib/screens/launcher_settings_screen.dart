import 'package:flutter/material.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import 'package:focuson_android_bridge/focuson_android_bridge.dart';
import 'hidden_apps_screen.dart';

class LauncherSettingsScreen extends StatefulWidget {
  final bool isDefaultLauncher;
  final bool isMinimalTextMode;
  final int columnCount;
  final Set<String> hiddenPackages;
  final List<InstalledAppInfo> allApps;
  final ValueChanged<bool> onToggleMode;
  final ValueChanged<int> onColumnChange;
  final Function(String) onUnhidePackage;
  final VoidCallback onRefreshDefaultStatus;

  const LauncherSettingsScreen({
    super.key,
    required this.isDefaultLauncher,
    required this.isMinimalTextMode,
    required this.columnCount,
    required this.hiddenPackages,
    required this.allApps,
    required this.onToggleMode,
    required this.onColumnChange,
    required this.onUnhidePackage,
    required this.onRefreshDefaultStatus,
  });

  @override
  State<LauncherSettingsScreen> createState() => _LauncherSettingsScreenState();
}

class _LauncherSettingsScreenState extends State<LauncherSettingsScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.onRefreshDefaultStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Launcher Settings'),
      ),
      body: ListView(
        padding: FocusSpacing.insetAllLg,
        children: [
          // Default Launcher Status Card
          FocusCard(
            padding: FocusSpacing.insetAllMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.isDefaultLauncher ? Icons.check_circle : Icons.warning_amber_rounded,
                      color: widget.isDefaultLauncher ? FocusColors.emeraldGreen : FocusColors.amberWarning,
                      size: 20,
                    ),
                    const SizedBox(width: FocusSpacing.sm),
                    Text(
                      widget.isDefaultLauncher ? 'FocusON is Default Home' : 'Default Home Not Set',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: FocusSpacing.xs),
                Text(
                  widget.isDefaultLauncher
                      ? 'Pressing your device Home button returns to FocusON Launcher.'
                      : 'To use FocusON as your everyday home screen, choose FocusON in Android Home app settings.',
                  style: const TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary),
                ),
                if (!widget.isDefaultLauncher) ...[
                  const SizedBox(height: FocusSpacing.md),
                  FocusButton(
                    label: 'Set as Default Home',
                    variant: FocusButtonVariant.primary,
                    isFullWidth: true,
                    onPressed: () async {
                      await FocusLauncherBridge.openHomeSettings();
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: FocusSpacing.lg),

          const FocusSectionHeader(title: 'HOME SCREEN MODE'),
          SwitchListTile(
            title: const Text('Minimal Text Mode'),
            subtitle: const Text('Distraction-free alphabetical text list instead of app icons.'),
            value: widget.isMinimalTextMode,
            activeColor: FocusColors.electricBlue,
            onChanged: (val) => widget.onToggleMode(val),
          ),

          if (!widget.isMinimalTextMode) ...[
            const SizedBox(height: FocusSpacing.md),
            const FocusSectionHeader(title: 'GRID COLUMNS'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.lg),
              child: Row(
                children: [3, 4, 5].map((cols) {
                  final isSelected = widget.columnCount == cols;
                  return Padding(
                    padding: const EdgeInsets.only(right: FocusSpacing.sm),
                    child: ChoiceChip(
                      label: Text('$cols Columns'),
                      selected: isSelected,
                      onSelected: (_) => widget.onColumnChange(cols),
                      selectedColor: FocusColors.electricBlue.withOpacity(0.2),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: FocusSpacing.lg),
          const FocusSectionHeader(title: 'APP MANAGEMENT'),
          ListTile(
            leading: const Icon(Icons.visibility_off_outlined),
            title: const Text('Hidden Apps'),
            subtitle: Text('${widget.hiddenPackages.length} apps hidden from launcher'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => HiddenAppsScreen(
                    allApps: widget.allApps,
                    hiddenPackages: widget.hiddenPackages,
                    onUnhidePackage: widget.onUnhidePackage,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
