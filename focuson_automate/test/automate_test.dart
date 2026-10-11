import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_rules_engine/focuson_rules_engine.dart';
import 'package:focuson_automate/main.dart';
import 'package:focuson_automate/screens/automate_home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  late FocusDatabase db;

  setUp(() async {
    db = await FocusDatabase.openInMemory();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('FocusON Automate boots and renders home screen', (tester) async {
    await tester.pumpWidget(FocusOnAutomateApp(db: db));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AutomateHomeScreen), findsOneWidget);
    expect(find.text('FocusON Automate'), findsOneWidget);
  });

  test('Templates can be imported into database rules', () async {
    final templates = AutomationTemplates.builtInTemplates;
    expect(templates.isNotEmpty, isTrue);

    final t = templates.first;
    await db.automationRepo.insertRule(t);

    final rules = await db.automationRepo.getAllRules();
    expect(rules.length, 1);
    expect(rules.first.title, t.title);
    expect(rules.first.triggerType, t.triggerType);
  });

  test('Rules engine dry-run and execution logging', () async {
    final engine = FocusRulesEngine();
    final rule = AutomationRule(
      title: 'Study Auto Focus',
      triggerType: TriggerType.profileActivated,
      triggerConfig: {'profile': 'study'},
      conditionType: ConditionType.activeProfile,
      conditionConfig: {'profile': 'study'},
      actionType: ActionType.startFocusSession,
      actionConfig: {'duration': 25},
    );
    await db.automationRepo.insertRule(rule);

    final ctx = RuleExecutionContext(
      currentProfile: ProfileType.study,
      batteryLevel: 80,
    );

    // Dry run
    final dryRunExec = await engine.executeRule(rule, ctx, isDryRun: true);
    expect(dryRunExec.isDryRun, isTrue);
    expect(dryRunExec.conditionsPassed, isTrue);
    expect(dryRunExec.actionResult, contains('Dry Run'));

    await db.automationRepo.recordExecution(dryRunExec);
    final history = await db.automationRepo.getExecutionHistory();
    expect(history.length, 1);
    expect(history.first.isDryRun, isTrue);
  });

  test('Rule toggling and deletion works correctly', () async {
    final rule = AutomationRule(
      title: 'Toggle Test Rule',
      triggerType: TriggerType.manual,
      conditionType: ConditionType.batteryLevel,
      actionType: ActionType.showNotification,
      isEnabled: true,
    );
    await db.automationRepo.insertRule(rule);

    await db.automationRepo.toggleRule(rule.id, false);
    var updated = (await db.automationRepo.getAllRules()).first;
    expect(updated.isEnabled, isFalse);

    await db.automationRepo.deleteRule(rule.id);
    final emptyRules = await db.automationRepo.getAllRules();
    expect(emptyRules.isEmpty, isTrue);
  });
}
