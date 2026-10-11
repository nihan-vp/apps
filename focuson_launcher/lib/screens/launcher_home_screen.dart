import 'package:flutter/material.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import 'package:focuson_android_bridge/focuson_android_bridge.dart';
import '../widgets/launcher_widgets.dart';
import 'icon_mode_view.dart';
import 'minimal_text_mode_view.dart';
import 'launcher_settings_screen.dart';

class LauncherHomeScreen extends StatefulWidget {
  final FocusDatabase db;

  const LauncherHomeScreen({super.key, required this.db});

  @override
  State<LauncherHomeScreen> createState() => _LauncherHomeScreenState();
}

class _LauncherHomeScreenState extends State<LauncherHomeScreen> with WidgetsBindingObserver {
  List<InstalledAppInfo> _allApps = [];
  List<InstalledAppInfo> _filteredApps = [];
  Set<String> _pinnedPackages = {};
  Set<String> _hiddenPackages = {};
  Set<String> _intentionPackages = {};
  bool _isMinimalTextMode = false;
  int _columnCount = 4;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isDefaultLauncher = false;
  List<Task> _todayTasks = [];
  FocusSession? _activeSession;
  RestrictionProfile? _activeProfile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLauncherData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDefaultLauncherStatus();
      _loadEcosystemWidgetsData();
    }
  }

  Future<void> _loadLauncherData() async {
    final apps = await FocusLauncherBridge.getInstalledApps();
    final isDefault = await FocusLauncherBridge.isDefaultLauncher();

    final isMinimal = await widget.db.preferencesRepo.getBool('launcher_minimal_mode', defaultValue: false);
    final cols = await widget.db.preferencesRepo.getInt('launcher_columns', defaultValue: 4);

    setState(() {
      _allApps = apps;
      _filteredApps = apps;
      _isDefaultLauncher = isDefault;
      _isMinimalTextMode = isMinimal;
      _columnCount = cols;
    });

    await _loadEcosystemWidgetsData();
  }

  Future<void> _checkDefaultLauncherStatus() async {
    final isDefault = await FocusLauncherBridge.isDefaultLauncher();
    if (mounted) setState(() => _isDefaultLauncher = isDefault);
  }

  Future<void> _loadEcosystemWidgetsData() async {
    final tasks = await widget.db.taskRepo.getTodayTasks();
    final session = await widget.db.controlRepo.getActiveFocusSession();
    final profile = await widget.db.controlRepo.getActiveProfile();

    if (mounted) {
      setState(() {
        _todayTasks = tasks;
        _activeSession = session;
        _activeProfile = profile;
      });
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.trim().isEmpty) {
        _filteredApps = _allApps;
      } else {
        final q = query.toLowerCase();
        _filteredApps = _allApps.where((a) => a.appName.toLowerCase().contains(q) || a.packageName.toLowerCase().contains(q)).toList();
      }
    });
  }

  void _togglePin(InstalledAppInfo app) {
    setState(() {
      if (_pinnedPackages.contains(app.packageName)) {
        _pinnedPackages.remove(app.packageName);
      } else {
        _pinnedPackages.add(app.packageName);
      }
    });
  }

  void _hideApp(InstalledAppInfo app) {
    setState(() {
      _hiddenPackages.add(app.packageName);
    });
  }

  void _unhideApp(String pkg) {
    setState(() {
      _hiddenPackages.remove(pkg);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = FocusTimeUtils.formatTime(now);
    final dateStr = FocusTimeUtils.formatReadableDate(now);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Home Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.lg, vertical: FocusSpacing.md),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.0,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 13, color: FocusColors.darkTextSecondary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (_activeProfile != null)
                    FocusProfileBadge(
                      type: _activeProfile!.type,
                      isSelected: true,
                    ),
                  const SizedBox(width: FocusSpacing.xs),
                  IconButton(
                    icon: Icon(
                      _isMinimalTextMode ? Icons.grid_view : Icons.format_list_bulleted,
                      color: FocusColors.electricBlue,
                    ),
                    tooltip: 'Toggle Icon / Minimal Text Mode',
                    onPressed: () async {
                      final newMode = !_isMinimalTextMode;
                      setState(() => _isMinimalTextMode = newMode);
                      await widget.db.preferencesRepo.setBool('launcher_minimal_mode', newMode);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Launcher Settings',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => LauncherSettingsScreen(
                            isDefaultLauncher: _isDefaultLauncher,
                            isMinimalTextMode: _isMinimalTextMode,
                            columnCount: _columnCount,
                            hiddenPackages: _hiddenPackages,
                            allApps: _allApps,
                            onToggleMode: (val) async {
                              setState(() => _isMinimalTextMode = val);
                              await widget.db.preferencesRepo.setBool('launcher_minimal_mode', val);
                            },
                            onColumnChange: (cols) async {
                              setState(() => _columnCount = cols);
                              await widget.db.preferencesRepo.setInt('launcher_columns', cols);
                            },
                            onUnhidePackage: _unhideApp,
                            onRefreshDefaultStatus: _checkDefaultLauncherStatus,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Embedded Widgets (only visible when not searching)
            if (_searchQuery.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.lg),
                child: Column(
                  children: [
                    PrioritiesWidget(
                      todayTasks: _todayTasks,
                      onRefresh: _loadEcosystemWidgetsData,
                      db: widget.db,
                    ),
                    const SizedBox(height: FocusSpacing.sm),
                    FocusTimerSummaryWidget(activeSession: _activeSession),
                    const SizedBox(height: FocusSpacing.sm),
                    QuickTaskEntryWidget(
                      db: widget.db,
                      onTaskAdded: _loadEcosystemWidgetsData,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FocusSpacing.md),
            ],

            // App Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.lg),
              child: FocusSearchBar(
                hint: 'Search installed applications...',
                onChanged: _onSearch,
              ),
            ),
            const SizedBox(height: FocusSpacing.sm),

            // Mode Views
            Expanded(
              child: _isMinimalTextMode
                  ? MinimalTextModeView(
                      apps: _filteredApps,
                      pinnedPackages: _pinnedPackages,
                      hiddenPackages: _hiddenPackages,
                      intentionPromptPackages: _intentionPackages,
                      onTogglePin: _togglePin,
                      onHideApp: _hideApp,
                    )
                  : IconModeView(
                      apps: _filteredApps,
                      pinnedPackages: _pinnedPackages,
                      hiddenPackages: _hiddenPackages,
                      intentionPromptPackages: _intentionPackages,
                      columnCount: _columnCount,
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
                      onTogglePin: _togglePin,
                      onHideApp: _hideApp,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
