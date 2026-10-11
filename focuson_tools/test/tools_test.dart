import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_tools/main.dart';
import 'package:focuson_tools/services/lan_drop_server.dart';
import 'package:focuson_tools/services/backup_service.dart';
import 'package:focuson_tools/utils/formatters.dart';
import 'package:focuson_tools/screens/tools_home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  late FocusDatabase db;
  late LanDropServer lanServer;

  setUp(() async {
    db = await FocusDatabase.openInMemory();
    lanServer = LanDropServer();
  });

  tearDown(() async {
    await lanServer.stop();
    await db.close();
  });

  testWidgets('FocusON Tools boots and displays utility categories', (tester) async {
    await tester.pumpWidget(FocusOnToolsApp(db: db, lanServer: lanServer));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ToolsHomeScreen), findsOneWidget);
    expect(find.text('FocusON Tools'), findsOneWidget);
    expect(find.text('JSON Formatter & CSV Converter'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Ecosystem Backup & Restore'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ecosystem Backup & Restore'), findsOneWidget);
  });

  test('Developer formatters: JSON, Base64, Hex, Epoch, and Diff', () {
    // JSON
    const rawJson = '{"a":1,"b":true}';
    final formatted = DevFormatters.formatJson(rawJson);
    expect(formatted, contains('\n'));

    // JSON to CSV
    const arrayJson = '[{"id":1,"name":"Alice"},{"id":2,"name":"Bob"}]';
    final csv = DevFormatters.jsonToCsv(arrayJson);
    expect(csv, contains('id,name'));
    expect(csv, contains('"Alice"'));

    // Base64
    final b64 = DevFormatters.base64EncodeText('FocusON');
    expect(DevFormatters.base64DecodeText(b64), 'FocusON');

    // Hex
    final hex = DevFormatters.hexEncodeText('ABC');
    expect(DevFormatters.hexDecodeText(hex), 'ABC');

    // Epoch
    final dt = DateTime(2026, 10, 11, 12, 0);
    final epoch = DevFormatters.dateTimeToEpoch(dt);
    final back = DevFormatters.epochToDateTime(epoch);
    expect(back.year, 2026);

    // Diff
    final diff = DevFormatters.computeDiff('line1\nline2', 'line1\nline3');
    expect(diff.any((d) => d.type == DiffType.added), isTrue);
    expect(diff.any((d) => d.type == DiffType.removed), isTrue);
  });

  test('Full ecosystem backup and restore round-trip across database tables', () async {
    // 1. Seed some data into db
    final task = Task(title: 'Critical Mission', priority: FocusPriority.urgent);
    await db.taskRepo.insertTask(task);

    final subject = Subject(name: 'Data Structures', code: 'CS-201');
    await db.academicRepo.insertSubject(subject);

    final deck = FlashcardDeck(title: 'Algorithm Trivia');
    await db.flashcardRepo.insertDeck(deck);

    // 2. Export ecosystem backup
    final backupService = EcosystemBackupService(db: db);
    final exportResult = await backupService.exportEcosystemData();

    expect(exportResult.success, isTrue);
    expect(exportResult.totalRecordsExported, greaterThanOrEqualTo(3));
    expect(exportResult.jsonPayload, contains('Critical Mission'));
    expect(exportResult.jsonPayload, contains('Data Structures'));
    expect(exportResult.jsonPayload, contains('Algorithm Trivia'));

    // 3. Open a fresh in-memory database to test restore
    final freshDb = await FocusDatabase.openInMemory();
    final freshBackupService = EcosystemBackupService(db: freshDb);

    final restoreResult = await freshBackupService.importEcosystemData(exportResult.jsonPayload);
    expect(restoreResult.success, isTrue);
    expect(restoreResult.totalRecordsImported, exportResult.totalRecordsExported);

    // Verify restored records in fresh db
    final restoredTask = await freshDb.taskRepo.getTaskById(task.id);
    expect(restoredTask?.title, 'Critical Mission');

    final restoredSubjects = await freshDb.academicRepo.getAllSubjects();
    expect(restoredSubjects.any((s) => s.code == 'CS-201'), isTrue);

    await freshDb.close();
  });

  test('LAN Drop server lifecycle and note clearing', () async {
    expect(lanServer.isRunning, isFalse);

    await lanServer.start(port: 0); // Port 0 binds to ephemeral free port
    expect(lanServer.isRunning, isTrue);

    lanServer.clearNotes();
    expect(lanServer.receivedNotes.isEmpty, isTrue);

    await lanServer.stop();
    expect(lanServer.isRunning, isFalse);
  });
}
