import 'package:flutter/material.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import 'package:focuson_database/focuson_database.dart';
import 'screens/automate_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = FocusDatabase();
  await db.open();
  runApp(FocusOnAutomateApp(db: db));
}

class FocusOnAutomateApp extends StatelessWidget {
  final FocusDatabase db;

  const FocusOnAutomateApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusON Automate',
      theme: FocusTheme.dark(),
      darkTheme: FocusTheme.amoled(),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: AutomateHomeScreen(db: db),
    );
  }
}
