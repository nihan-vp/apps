import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_android_bridge/focuson_android_bridge.dart';
import 'package:focuson_launcher/main.dart';
import 'package:focuson_launcher/screens/launcher_home_screen.dart';

void main() {
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

  testWidgets('FocusON Launcher boots and displays home screen', (tester) async {
    await tester.pumpWidget(FocusLauncherApp(db: db));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(LauncherHomeScreen), findsOneWidget);
  });

  test('Launcher settings persist across restarts', () async {
    await db.preferencesRepo.setBool('launcher_minimal_mode', true);
    await db.preferencesRepo.setInt('launcher_columns', 3);

    expect(await db.preferencesRepo.getBool('launcher_minimal_mode'), isTrue);
    expect(await db.preferencesRepo.getInt('launcher_columns'), 3);
  });

  test('Installed apps discovery returns available items', () async {
    final apps = await FocusLauncherBridge.getInstalledApps();
    expect(apps.isNotEmpty, isTrue);
    expect(apps.any((a) => a.packageName == 'com.focuson.control'), isTrue);
  });
}
