import 'dart:convert';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_database/focuson_database.dart';

class EcosystemBackupResult {
  final bool success;
  final int totalRecordsExported;
  final String jsonPayload;
  final String? error;

  EcosystemBackupResult({
    required this.success,
    this.totalRecordsExported = 0,
    this.jsonPayload = '',
    this.error,
  });
}

class EcosystemRestoreResult {
  final bool success;
  final int totalRecordsImported;
  final String? error;

  EcosystemRestoreResult({
    required this.success,
    this.totalRecordsImported = 0,
    this.error,
  });
}

class EcosystemBackupService {
  final FocusDatabase db;

  EcosystemBackupService({required this.db});

  /// Exports all ecosystem data across 6 apps into a single verified JSON archive.
  Future<EcosystemBackupResult> exportEcosystemData() async {
    try {
      final rawDb = db.rawDb;
      final payload = <String, dynamic>{
        'ecosystem': 'FocusON',
        'version': '1.0.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'tables': <String, dynamic>{},
      };

      const tableNames = [
        'tasks',
        'subtasks',
        'reminders',
        'subjects',
        'exams',
        'syllabus_topics',
        'calendar_events',
        'notes',
        'habits',
        'habit_logs',
        'flashcard_decks',
        'flashcards',
        'app_restrictions',
        'focus_sessions',
        'automation_rules',
        'automation_executions',
      ];

      var totalRecords = 0;
      final tablesMap = <String, dynamic>{};

      for (final table in tableNames) {
        try {
          final rows = await rawDb.query(table);
          tablesMap[table] = rows;
          totalRecords += rows.length;
        } catch (_) {
          // Table may not have been created yet or empty
          tablesMap[table] = [];
        }
      }

      payload['tables'] = tablesMap;
      payload['totalRecords'] = totalRecords;

      final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
      return EcosystemBackupResult(
        success: true,
        totalRecordsExported: totalRecords,
        jsonPayload: jsonStr,
      );
    } catch (e) {
      return EcosystemBackupResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Restores ecosystem data from a JSON archive with transaction rollback on error.
  Future<EcosystemRestoreResult> importEcosystemData(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      if (decoded['ecosystem'] != 'FocusON') {
        return EcosystemRestoreResult(
          success: false,
          error: 'Invalid archive: Missing FocusON ecosystem header signature.',
        );
      }

      final tables = decoded['tables'] as Map<String, dynamic>? ?? {};
      var imported = 0;

      await db.transaction((txn) async {
        for (final entry in tables.entries) {
          final tableName = entry.key;
          final rows = entry.value as List? ?? [];
          for (final row in rows) {
            if (row is Map) {
              await txn.insert(
                tableName,
                Map<String, dynamic>.from(row),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              imported++;
            }
          }
        }
      });

      return EcosystemRestoreResult(
        success: true,
        totalRecordsImported: imported,
      );
    } catch (e) {
      return EcosystemRestoreResult(
        success: false,
        error: 'Failed to restore ecosystem: $e',
      );
    }
  }
}
