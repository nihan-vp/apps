import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_control/main.dart';
import 'package:focuson_control/screens/control_dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  late FocusDatabase db;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.focuson.bridge/usage'), (call) async {
      if (call.method == 'hasUsageAccess') return true;
      if (call.method == 'queryUsageStats') return [];
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.focuson.bridge/restrictions'), (call) async {
      if (call.method == 'isOverlayPermitted') return true;
      return null;
    });

    db = await FocusDatabase.openInMemory();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('FocusON Control boots and displays dashboard', (tester) async {
    await tester.pumpWidget(FocusControlApp(db: db));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ControlDashboardScreen), findsOneWidget);
    expect(find.text('Screen Time'), findsOneWidget);
    expect(find.text('Focus Duration'), findsOneWidget);
  });

  test('Restriction rules persist and support pause/resume', () async {
    final rule = RestrictionRule(
      packageName: 'com.social.network',
      appName: 'Social App',
      preset: RestrictionPreset.smart,
      dailyLimitMinutes: 30,
    );
    await db.controlRepo.insertRestrictionRule(rule);

    var rules = await db.controlRepo.getAllRestrictionRules();
    expect(rules.length, 1);
    expect(rules.first.isPaused, isFalse);

    // Pause rule
    await db.controlRepo.updateRestrictionRule(rule.copyWith(isPaused: true));
    rules = await db.controlRepo.getAllRestrictionRules();
    expect(rules.first.isPaused, isTrue);
  });

  test('Focus session tracks state accurately', () async {
    final session = FocusSession(
      title: 'Math Study',
      intention: 'Calculus derivatives',
      targetDurationMinutes: 25,
      state: SessionState.running,
      startedAt: DateTime.now(),
    );
    await db.controlRepo.insertFocusSession(session);

    final active = await db.controlRepo.getActiveFocusSession();
    expect(active, isNotNull);
    expect(active?.intention, 'Calculus derivatives');
    expect(active?.state, SessionState.running);
  });
}
