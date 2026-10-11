import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import 'screens/planner_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = FocusDatabase();
  await db.open();

  // Check if incoming text was shared into Planner via Android Share Intent
  String? sharedText;
  try {
    const channel = MethodChannel('com.focuson.bridge/share');
    sharedText = await channel.invokeMethod<String>('getSharedText');
  } catch (_) {}

  runApp(FocusPlannerApp(db: db, sharedText: sharedText));
}

class FocusPlannerApp extends StatelessWidget {
  final FocusDatabase db;
  final String? sharedText;

  const FocusPlannerApp({super.key, required this.db, this.sharedText});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusON Planner',
      debugShowCheckedModeBanner: false,
      theme: FocusTheme.dark(),
      darkTheme: FocusTheme.amoled(),
      themeMode: ThemeMode.dark,
      home: PlannerHomeScreen(db: db, sharedText: sharedText),
    );
  }
}
