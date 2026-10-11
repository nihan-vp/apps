import 'package:flutter/material.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import 'package:focuson_android_bridge/focuson_android_bridge.dart';
import '../widgets/intention_dialog.dart';

class IconModeView extends StatelessWidget {
  final List<InstalledAppInfo> apps;
  final Set<String> pinnedPackages;
  final Set<String> hiddenPackages;
  final Set<String> intentionPromptPackages;
  final int columnCount;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final Function(InstalledAppInfo) onTogglePin;
  final Function(InstalledAppInfo) onHideApp;

  const IconModeView({
    super.key,
    required this.apps,
    required this.pinnedPackages,
    required this.hiddenPackages,
    required this.intentionPromptPackages,
    this.columnCount = 4,
    required this.selectedCategory,
    required this.onCategorySelected,
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

    final filteredApps = selectedCategory == 'All'
        ? visibleApps
        : visibleApps.where((a) => a.category == selectedCategory).toList();

    final pinnedApps = visibleApps.where((a) => pinnedPackages.contains(a.packageName)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pinned row
        if (pinnedApps.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: FocusSpacing.lg, vertical: FocusSpacing.xs),
            child: Text(
              'PINNED',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: FocusColors.electricBlue),
            ),
          ),
          SizedBox(
            height: 85,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.md),
              itemCount: pinnedApps.length,
              itemBuilder: (context, index) {
                final app = pinnedApps[index];
                return GestureDetector(
                  onTap: () => _handleAppLaunch(context, app),
                  onLongPress: () => _showAppMenu(context, app),
                  child: Container(
                    width: 72,
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAppAvatar(app, isDark, size: 44),
                        const SizedBox(height: 4),
                        Text(
                          app.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: FocusSpacing.sm),
        ],

        // Categories
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.lg),
            children: ['All', 'FocusON Ecosystem', 'Productivity', 'Utilities', 'Communication', 'System'].map((cat) {
              final isSelected = selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: FocusSpacing.sm),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) => onCategorySelected(cat),
                  backgroundColor: isDark ? FocusColors.darkSurfaceHigh : FocusColors.lightSurfaceHigh,
                  selectedColor: FocusColors.electricBlue.withOpacity(0.2),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? FocusColors.electricBlue : (isDark ? FocusColors.darkTextSecondary : FocusColors.lightTextSecondary),
                  ),
                  side: BorderSide(
                    color: isSelected ? FocusColors.electricBlue : (isDark ? FocusColors.darkBorder : FocusColors.lightBorder),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: FocusSpacing.md),

        // Apps Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.lg, vertical: FocusSpacing.sm),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: filteredApps.length,
            itemBuilder: (context, index) {
              final app = filteredApps[index];
              return InkWell(
                onTap: () => _handleAppLaunch(context, app),
                onLongPress: () => _showAppMenu(context, app),
                borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAppAvatar(app, isDark, size: 50),
                    const SizedBox(height: FocusSpacing.xs),
                    Text(
                      app.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppAvatar(InstalledAppInfo app, bool isDark, {required double size}) {
    final isEcosystem = app.packageName.startsWith('com.focuson.');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isEcosystem
            ? FocusColors.electricBlue.withOpacity(0.2)
            : (isDark ? FocusColors.darkSurfaceHigh : FocusColors.lightSurfaceHigh),
        borderRadius: BorderRadius.circular(FocusSpacing.radiusLg),
        border: Border.all(
          color: isEcosystem
              ? FocusColors.electricBlue
              : (isDark ? FocusColors.darkBorder : FocusColors.lightBorder),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Text(
          app.appName.isNotEmpty ? app.appName[0].toUpperCase() : 'A',
          style: TextStyle(
            fontSize: size * 0.45,
            fontWeight: FontWeight.w700,
            color: isEcosystem ? FocusColors.electricBlue : (isDark ? FocusColors.darkTextPrimary : FocusColors.lightTextPrimary),
          ),
        ),
      ),
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
              leading: const Icon(Icons.apps, color: FocusColors.electricBlue),
              title: Text(app.appName, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(app.packageName, style: const TextStyle(fontSize: 12, color: FocusColors.darkTextMuted)),
            ),
            const Divider(),
            ListTile(
              leading: Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin),
              title: Text(isPinned ? 'Unpin from Top' : 'Pin to Top'),
              onTap: () {
                Navigator.of(ctx).pop();
                onTogglePin(app);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Hide from Home Screen'),
              subtitle: const Text('Removes from launcher without uninstalling', style: TextStyle(fontSize: 11)),
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
