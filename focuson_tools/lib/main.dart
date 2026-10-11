import 'package:flutter/material.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import 'services/lan_drop_server.dart';
import 'screens/tools_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = FocusDatabase();
  await db.open();
  final lanServer = LanDropServer();

  runApp(FocusOnToolsApp(db: db, lanServer: lanServer));
}

class FocusOnToolsApp extends StatelessWidget {
  final FocusDatabase db;
  final LanDropServer lanServer;

  const FocusOnToolsApp({super.key, required this.db, required this.lanServer});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusON Tools',
      theme: FocusTheme.dark(),
      darkTheme: FocusTheme.amoled(),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: ToolsHomeScreen(db: db, lanServer: lanServer),
    );
  }
}
