import 'package:flutter/material.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import 'package:focuson_android_bridge/focuson_android_bridge.dart';

class UsageAnalyticsScreen extends StatefulWidget {
  final FocusDatabase db;

  const UsageAnalyticsScreen({super.key, required this.db});

  @override
  State<UsageAnalyticsScreen> createState() => _UsageAnalyticsScreenState();
}

class _UsageAnalyticsScreenState extends State<UsageAnalyticsScreen> {
  int _selectedPeriod = 0; // 0 = Day, 1 = Week, 2 = Month
  List<AppUsageRecord> _records = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUsage();
  }

  Future<void> _fetchUsage() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();

    DateTime start;
    if (_selectedPeriod == 0) {
      start = FocusTimeUtils.startOfDay(now);
    } else if (_selectedPeriod == 1) {
      start = now.subtract(const Duration(days: 7));
    } else {
      start = now.subtract(const Duration(days: 30));
    }

    final hasPerm = await FocusUsageBridge.hasUsageAccess();
    if (hasPerm) {
      final bridgeStats = await FocusUsageBridge.queryUsageStats(start, now);
      for (final r in bridgeStats) {
        await widget.db.controlRepo.recordAppUsage(r);
      }
    }

    final data = await widget.db.controlRepo.getUsageRange(start, now);
    if (mounted) {
      setState(() {
        _records = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalSeconds = _records.fold<int>(0, (sum, r) => sum + r.durationSeconds);
    final totalDurationStr = FocusTimeUtils.formatDuration(Duration(seconds: totalSeconds));

    return Scaffold(
      body: ListView(
        padding: FocusSpacing.insetAllLg,
        children: [
          // Period selector
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Today')),
              ButtonSegment(value: 1, label: Text('Last 7 Days')),
              ButtonSegment(value: 2, label: Text('Last 30 Days')),
            ],
            selected: {_selectedPeriod},
            onSelectionChanged: (set) {
              setState(() => _selectedPeriod = set.first);
              _fetchUsage();
            },
          ),
          const SizedBox(height: FocusSpacing.md),

          // Total time banner
          FocusCard(
            padding: FocusSpacing.insetAllMd,
            child: Row(
              children: [
                const Icon(Icons.analytics_outlined, color: FocusColors.electricBlue, size: 28),
                const SizedBox(width: FocusSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Measured Time',
                        style: TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary),
                      ),
                      Text(
                        totalDurationStr.isEmpty ? '0m' : totalDurationStr,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: FocusColors.coralDanger),
                  tooltip: 'Clear Cached History',
                  onPressed: () async {
                    final confirmed = await FocusDialog.show(
                      context,
                      title: 'Clear Usage History',
                      message: 'This will permanently remove locally stored screen time history. Real usage remains in Android system settings.',
                      confirmLabel: 'Clear',
                      isDestructive: true,
                    );
                    if (confirmed == true) {
                      await widget.db.controlRepo.clearUsageHistory();
                      _fetchUsage();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: FocusSpacing.md),

          // Honest API Disclosure
          Container(
            padding: FocusSpacing.insetAllMd,
            decoration: BoxDecoration(
              color: isDark ? FocusColors.darkSurfaceHigh : FocusColors.lightSurfaceHigh,
              borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
              border: Border.all(color: isDark ? FocusColors.darkBorder : FocusColors.lightBorder),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: FocusColors.emeraldGreen, size: 20),
                SizedBox(width: FocusSpacing.sm),
                Expanded(
                  child: Text(
                    'FocusON strictly reads foreground session statistics provided by Android UsageStatsManager. Ordinary Android APIs do not track individual reels, shorts, or swipe interactions.',
                    style: TextStyle(fontSize: 12, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: FocusSpacing.lg),

          const FocusSectionHeader(title: 'APPLICATION BREAKDOWN'),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_records.isEmpty)
            const FocusEmptyState(
              icon: Icons.hourglass_empty,
              title: 'No Usage Data',
              message: 'Grant Usage Access in Android Settings to view detailed application time.',
            )
          else
            ..._records.map((r) {
              final pct = totalSeconds > 0 ? (r.durationSeconds / totalSeconds) : 0.0;
              final durStr = FocusTimeUtils.formatDuration(Duration(seconds: r.durationSeconds));

              return Padding(
                padding: const EdgeInsets.only(bottom: FocusSpacing.sm),
                child: FocusCard(
                  padding: FocusSpacing.insetAllMd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.appName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                          Text(
                            durStr,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: FocusColors.electricBlue),
                          ),
                        ],
                      ),
                      const SizedBox(height: FocusSpacing.xs),
                      Row(
                        children: [
                          Text(
                            '${(pct * 100).toStringAsFixed(1)}% of total time',
                            style: const TextStyle(fontSize: 11, color: FocusColors.darkTextMuted),
                          ),
                          const Spacer(),
                          if (r.launchCount > 0)
                            Text(
                              '${r.launchCount} launches',
                              style: const TextStyle(fontSize: 11, color: FocusColors.darkTextMuted),
                            ),
                        ],
                      ),
                      const SizedBox(height: FocusSpacing.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(FocusSpacing.radiusPill),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 4,
                          backgroundColor: isDark ? FocusColors.darkSurfaceHigh : FocusColors.lightSurfaceHigh,
                          valueColor: const AlwaysStoppedAnimation<Color>(FocusColors.electricBlue),
                        ),
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
