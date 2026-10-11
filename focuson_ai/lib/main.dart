import 'package:flutter/material.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import 'services/ai_service.dart';
import 'screens/ai_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = FocusDatabase();
  await db.open();
  final aiService = AIService(db: db);

  runApp(FocusOnAIApp(db: db, aiService: aiService));
}

class FocusOnAIApp extends StatelessWidget {
  final FocusDatabase db;
  final AIService aiService;

  const FocusOnAIApp({super.key, required this.db, required this.aiService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusON AI',
      theme: FocusTheme.dark(),
      darkTheme: FocusTheme.amoled(),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: AIHomeScreen(db: db, aiService: aiService),
    );
  }
}
