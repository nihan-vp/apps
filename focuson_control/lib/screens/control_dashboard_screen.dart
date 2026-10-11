import 'package:flutter/material.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import 'package:focuson_android_bridge/focuson_android_bridge.dart';
import 'usage_analytics_screen.dart';
import 'restrictions_screen.dart';
import 'focus_session_screen.dart';
import 'profiles_screen.dart';

class ControlDashboardScreen extends StatefulWidget {
  final FocusDatabase db;

  const ControlDashboardScreen({super.key, required this.db});

  @override
  State<ControlDashboardScreen> createState() => _ControlDashboardScreenState();
}

class _ControlDashboardScreenState extends State<ControlDashboardScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _hasUsageAccess = false;
  List<AppUsageRecord> _todayUsage = [];
  FocusSession? _activeSession;
  RestrictionProfile? _activeProfile;
  List<RestrictionRule> _activeRules = [];
  int _todayFocusMinutes = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    final hasPerm = await FocusUsageBridge.hasUsageAccess();
    final profile = await widget.db.controlRepo.getActiveProfile();
    final session = await widget.db.controlRepo.getActiveFocusSession();
    final rules = await widget.db.controlRepo.getAllRestrictionRules();

    final now = DateTime.now();
    var usage = await widget.db.controlRepo.getUsageForDay(now);

    // If permission is available and local DB has no records for today, query from bridge
    if (hasPerm && usage.isEmpty) {
      final start = FocusTimeUtils.startOfDay(now);
      final bridgeStats = await FocusUsageBridge.queryUsageStats(start, now);
      for (final r in bridgeStats) {
        await widget.db.controlRepo.recordAppUsage(r);
      }
      usage = await widget.db.controlRepo.getUsageForDay(now);
    }

    final history = await widget.db.controlRepo.getSessionHistory();
    final todayFocus = history
        .where((s) => s.completedAt != null && FocusTimeUtils.isSameDay(s.completedAt!, now))
        .fold<int>(0, (sum, s) => sum + (s.actualDurationSeconds ~/ 60));

    if (mounted) {
      setState(() {
        _hasUsageAccess = hasPerm;
        _activeProfile = profile ?? RestrictionProfile(name: 'Study', type: ProfileType.study, isActive: true);
        _activeSession = session;
        _activeRules = rules.where((r) => !r.isPaused).toList();
        _todayUsage = usage;
        _todayFocusMinutes = todayFocus;
      });
    }
  }

  Widget _buildDashboardTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalSeconds = _todayUsage.fold<int>(0, (sum, r) => sum + r.durationSeconds);
    final screenTimeDuration = Duration(seconds: totalSeconds);
    final formattedScreenTime = FocusTimeUtils.formatDuration(screenTimeDuration);

    return ListView(
      padding: FocusSpacing.insetAllLg,
      children: [
        // Permission Banner if missing
        if (!_hasUsageAccess)
          FocusPermissionBanner(
            permission: PermissionType.usageAccess,
            onGrant: () async {
              await FocusUsageBridge.openUsageAccessSettings();
            },
          ),

        // Screen time stat & Focus duration cards
        Row(
          children: [
            Expanded(
              child: FocusStatCard(
                title: 'Screen Time',
                value: formattedScreenTime.isEmpty ? '0m' : formattedScreenTime,
                subtitle: _hasUsageAccess ? 'Measured via Android' : 'Permission needed',
                icon: Icons.smartphone,
                accentColor: FocusColors.electricBlue,
              ),
            ),
            const SizedBox(width: FocusSpacing.md),
            Expanded(
              child: FocusStatCard(
                title: 'Focus Duration',
                value: '${_todayFocusMinutes}m',
                subtitle: 'Deep work today',
                icon: Icons.timer,
                accentColor: FocusColors.emeraldGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: FocusSpacing.md),

        // Active Focus Session Banner
        if (_activeSession != null && _activeSession!.state == SessionState.running) ...[
          FocusCard(
            backgroundColor: FocusColors.amberWarning.withOpacity(0.12),
            borderColor: FocusColors.amberWarning.withOpacity(0.4),
            padding: FocusSpacing.insetAllMd,
            child: Row(
              children: [
                const Icon(Icons.hourglass_top, color: FocusColors.amberWarning, size: 24),
                const SizedBox(width: FocusSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Focus Session',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        'Target: ${_activeSession!.targetDurationMinutes} min • ${_activeSession!.intention}',
                        style: const TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                FocusButton(
                  label: 'Resume',
                  height: 32,
                  variant: FocusButtonVariant.primary,
                  onPressed: () {
                    setState(() => _currentIndex = 3); // Switch to Focus Timer tab
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: FocusSpacing.md),
        ],

        // Current Profile
        FocusSectionHeader(
          title: 'ACTIVE PROFILE',
          actionLabel: 'Switch',
          onAction: () => setState(() => _currentIndex = 4),
        ),
        FocusCard(
          padding: FocusSpacing.insetAllMd,
          child: Row(
            children: [
              FocusProfileBadge(
                type: _activeProfile?.type ?? ProfileType.study,
                isSelected: true,
              ),
              const SizedBox(width: FocusSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activeProfile?.name ?? 'Study Profile',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${_activeProfile?.defaultFocusMinutes ?? 25}m focus defaults • ${_activeProfile?.notificationMode ?? "priority_only"}',
                      style: TextStyle(fontSize: 12, color: isDark ? FocusColors.darkTextMuted : FocusColors.lightTextMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: FocusSpacing.md),

        // Most Used Apps
        FocusSectionHeader(
          title: 'MOST USED APPS',
          actionLabel: 'Full Insights',
          onAction: () => setState(() => _currentIndex = 1),
        ),
        if (_todayUsage.isEmpty)
          FocusCard(
            padding: FocusSpacing.insetAllMd,
            child: Text(
              _hasUsageAccess
                  ? 'No app usage recorded yet today.'
                  : 'Grant Usage Access to view real screen time measurements.',
              style: TextStyle(fontSize: 13, color: isDark ? FocusColors.darkTextMuted : FocusColors.lightTextMuted),
            ),
          )
        else
          Column(
            children: _todayUsage.take(3).map((record) {
              final dur = FocusTimeUtils.formatDuration(Duration(seconds: record.durationSeconds));
              return Padding(
                padding: const EdgeInsets.only(bottom: FocusSpacing.xs),
                child: FocusCard(
                  padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.md, vertical: FocusSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: FocusColors.darkSurfaceHigh,
                          borderRadius: BorderRadius.circular(FocusSpacing.radiusSm),
                        ),
                        child: Center(
                          child: Text(
                            record.appName.isNotEmpty ? record.appName[0] : 'A',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: FocusSpacing.md),
                      Expanded(
                        child: Text(
                          record.appName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      Text(
                        dur,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: FocusColors.electricBlue),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: FocusSpacing.md),

        // Configured Restrictions
        FocusSectionHeader(
          title: 'ACTIVE RESTRICTIONS',
          actionLabel: 'Manage',
          onAction: () => setState(() => _currentIndex = 2),
        ),
        if (_activeRules.isEmpty)
          FocusCard(
            padding: FocusSpacing.insetAllMd,
            child: const Text(
              'No active app restrictions. Configure limits to guard your time.',
              style: TextStyle(fontSize: 13, color: FocusColors.darkTextMuted),
            ),
          )
        else
          Column(
            children: _activeRules.take(3).map((rule) {
              return Padding(
                padding: const EdgeInsets.only(bottom: FocusSpacing.xs),
                child: FocusCard(
                  padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.md, vertical: FocusSpacing.sm),
                  child: Row(
                    children: [
                      const Icon(Icons.block, size: 18, color: FocusColors.coralDanger),
                      const SizedBox(width: FocusSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rule.appName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              '${rule.preset.displayName} • ${rule.dailyLimitMinutes}m daily limit',
                              style: const TextStyle(fontSize: 11, color: FocusColors.darkTextMuted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: FocusColors.emeraldGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: FocusColors.emeraldGreen),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return UsageAnalyticsScreen(db: widget.db);
      case 2:
        return RestrictionsScreen(db: widget.db);
      case 3:
        return FocusSessionScreen(db: widget.db);
      case 4:
        return ProfilesScreen(db: widget.db);
      default:
        return _buildDashboardTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'FocusON Control'
              : (_currentIndex == 1
                  ? 'Usage Analytics'
                  : (_currentIndex == 2
                      ? 'App Restrictions'
                      : (_currentIndex == 3 ? 'Focus Timer' : 'Profiles'))),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: 'Restrictions'),
          NavigationDestination(icon: Icon(Icons.timer_outlined), selectedIcon: Icon(Icons.timer), label: 'Focus'),
          NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune), label: 'Profiles'),
        ],
      ),
    );
  }
}
