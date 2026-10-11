import 'package:flutter/material.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import 'package:focuson_interop/focuson_interop.dart';
import 'screens/control_dashboard_screen.dart';
import 'screens/focus_session_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = FocusDatabase();
  await db.open();

  runApp(FocusControlApp(db: db));
}

class FocusControlApp extends StatefulWidget {
  final FocusDatabase db;
  final Uri? initialUri;

  const FocusControlApp({super.key, required this.db, this.initialUri});

  @override
  State<FocusControlApp> createState() => _FocusControlAppState();
}

class _FocusControlAppState extends State<FocusControlApp> {
  StartSessionContract? _pendingSession;

  @override
  void initState() {
    super.initState();
    if (widget.initialUri != null) {
      _handleDeepLink(widget.initialUri!);
    }
  }

  void _handleDeepLink(Uri uri) {
    final contract = StartSessionContract.fromUri(uri);
    if (contract != null) {
      setState(() => _pendingSession = contract);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusON Control',
      debugShowCheckedModeBanner: false,
      theme: FocusTheme.dark(),
      darkTheme: FocusTheme.amoled(),
      themeMode: ThemeMode.dark,
      home: _pendingSession != null
          ? FocusSessionScreen(
              db: widget.db,
              initialDurationMinutes: _pendingSession!.durationMinutes,
              initialIntention: _pendingSession!.intention,
              initialTaskId: _pendingSession!.linkedTaskId,
            )
          : ControlDashboardScreen(db: widget.db),
    );
  }
}
