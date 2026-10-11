import 'package:flutter/material.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import 'package:focuson_android_bridge/focuson_android_bridge.dart';

class HiddenAppsScreen extends StatelessWidget {
  final List<InstalledAppInfo> allApps;
  final Set<String> hiddenPackages;
  final Function(String) onUnhidePackage;

  const HiddenAppsScreen({
    super.key,
    required this.allApps,
    required this.hiddenPackages,
    required this.onUnhidePackage,
  });

  @override
  Widget build(BuildContext context) {
    final hiddenList = allApps.where((a) => hiddenPackages.contains(a.packageName)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hidden Apps'),
      ),
      body: Column(
        children: [
          Container(
            padding: FocusSpacing.insetAllMd,
            margin: FocusSpacing.insetAllMd,
            decoration: BoxDecoration(
              color: FocusColors.electricBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
              border: Border.all(color: FocusColors.electricBlue.withOpacity(0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: FocusColors.electricBlue, size: 20),
                SizedBox(width: FocusSpacing.sm),
                Expanded(
                  child: Text(
                    'Apps listed here are hidden from your home screen to reduce temptation. They remain installed on your device and are not blocked.',
                    style: TextStyle(fontSize: 12, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: hiddenList.isEmpty
                ? const FocusEmptyState(
                    icon: Icons.visibility,
                    title: 'No Hidden Apps',
                    message: 'Long-press any app on your home screen to hide it.',
                  )
                : ListView.builder(
                    itemCount: hiddenList.length,
                    itemBuilder: (context, index) {
                      final app = hiddenList[index];
                      return ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: FocusColors.darkSurfaceHigh,
                            borderRadius: BorderRadius.circular(FocusSpacing.radiusSm),
                          ),
                          child: Center(
                            child: Text(
                              app.appName.isNotEmpty ? app.appName[0] : 'A',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        title: Text(app.appName),
                        subtitle: Text(app.packageName, style: const TextStyle(fontSize: 11)),
                        trailing: FocusButton(
                          label: 'Unhide',
                          height: 32,
                          variant: FocusButtonVariant.secondary,
                          onPressed: () => onUnhidePackage(app.packageName),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
