import 'package:flutter/material.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import 'package:sqflite/sqflite.dart';
import 'screens/launcher_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = FocusDatabase(factory: databaseFactory);
  await db.open();

  runApp(FocusLauncherApp(db: db));
}

class FocusLauncherApp extends StatelessWidget {
  final FocusDatabase db;

  const FocusLauncherApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusON Launcher',
      debugShowCheckedModeBanner: false,
      theme: FocusTheme.dark(),
      darkTheme: FocusTheme.amoled(),
      themeMode: ThemeMode.dark,
      home: LauncherHomeScreen(db: db),
    );
  }
}
