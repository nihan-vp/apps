import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_launcher/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.focuson.bridge/launcher'), (call) async {
      if (call.method == 'isDefaultLauncher') return false;
      if (call.method == 'getInstalledApps') return [];
      return null;
    });
  });

  testWidgets('Launcher boots with mock channel', (tester) async {
    final db = await FocusDatabase.openInMemory();
    await tester.pumpWidget(FocusLauncherApp(db: db));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Toggle Icon / Minimal Text Mode'), findsOneWidget);
    await tester.tap(find.byTooltip('Toggle Icon / Minimal Text Mode'));
    await tester.pumpAndSettle();
    expect(await db.preferencesRepo.getBool('launcher_minimal_mode'), isTrue);
    await db.close();
  });
}
