import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_ai/main.dart';
import 'package:focuson_ai/services/ai_service.dart';
import 'package:focuson_ai/screens/ai_home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  late FocusDatabase db;
  late AIService aiService;

  setUp(() async {
    db = await FocusDatabase.openInMemory();
    aiService = AIService(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('FocusON AI boots and displays home screen with provider badge', (tester) async {
    await tester.pumpWidget(FocusOnAIApp(db: db, aiService: aiService));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AIHomeScreen), findsOneWidget);
    expect(find.text('FocusON AI'), findsOneWidget);
    expect(find.text('Local Offline'), findsOneWidget);
    expect(find.text('Task Breakdown'), findsOneWidget);
  });

  test('AIService breaks down complex tasks into ordered subtasks', () async {
    final task = Task(title: 'Write research paper on neural network architectures');
    final subtasks = await aiService.breakdownTask(task);

    expect(subtasks.isNotEmpty, isTrue);
    expect(subtasks.length, greaterThanOrEqualTo(3));
    expect(subtasks.first.title, contains('Outline'));
    expect(subtasks.last.sortOrder, subtasks.length - 1);
  });

  test('AIService schedule optimizer generates prioritized time blocks', () async {
    final tasks = [
      Task(title: 'High priority urgent bug', priority: FocusPriority.urgent),
      Task(title: 'Documentation polish', priority: FocusPriority.low),
    ];

    final plan = await aiService.generateDailyPlan(tasks, 3);
    expect(plan.isNotEmpty, isTrue);
    expect(plan.first.title, contains('High priority urgent bug'));
    expect(plan.first.allocatedMinutes, 50);
  });

  test('AIService honestly blocks execution when unconfigured without hallucinating', () async {
    aiService.updateConfig(
      mode: AIProviderMode.unconfigured,
      endpoint: '',
      apiKey: '',
      modelName: '',
      allowTelemetry: false,
    );

    expect(aiService.isConfigured, isFalse);
    expect(
      () => aiService.parseTask('Sample task'),
      throwsA(isA<StateError>()),
    );
  });
}
