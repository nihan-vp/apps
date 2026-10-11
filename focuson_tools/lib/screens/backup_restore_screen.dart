import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import '../services/backup_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  final FocusDatabase db;

  const BackupRestoreScreen({super.key, required this.db});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  late final EcosystemBackupService _backupService;
  bool _isProcessing = false;
  String _backupJson = '';
  int _exportedCount = 0;
  String? _statusMessage;
  final TextEditingController _importCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _backupService = EcosystemBackupService(db: widget.db);
  }

  @override
  void dispose() {
    _importCtrl.dispose();
    super.dispose();
  }

  void _runExport() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    final res = await _backupService.exportEcosystemData();

    setState(() {
      _isProcessing = false;
      if (res.success) {
        _backupJson = res.jsonPayload;
        _exportedCount = res.totalRecordsExported;
        _statusMessage = 'Backup completed: Exported $_exportedCount total records across all ecosystem apps.';
      } else {
        _statusMessage = 'Export failed: ${res.error}';
      }
    });
  }

  void _runImport() async {
    final text = _importCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    final res = await _backupService.importEcosystemData(text);

    setState(() {
      _isProcessing = false;
      if (res.success) {
        _statusMessage = 'Successfully restored ${res.totalRecordsImported} records into the ecosystem database!';
      } else {
        _statusMessage = 'Import error: ${res.error}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ecosystem Backup & Restore'),
      ),
      body: ListView(
        padding: FocusSpacing.insetAllLg,
        children: [
          // INFO CARD
          FocusCard(
            borderColor: FocusColors.emeraldGreen.withOpacity(0.5),
            padding: FocusSpacing.insetAllMd,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, color: FocusColors.emeraldGreen, size: 20),
                    SizedBox(width: FocusSpacing.xs),
                    Text('Universal Offline Ecosystem Backup', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: FocusColors.emeraldGreen)),
                  ],
                ),
                SizedBox(height: FocusSpacing.xs),
                Text(
                  'Exports tasks, flashcards, habits, academic syllabi, notes, restrictions, and automation workflows from all 6 apps into a single self-contained JSON archive.',
                  style: TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: FocusSpacing.lg),

          // EXPORT SECTION
          const Text('1. Export Ecosystem Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: FocusSpacing.xs),
          FocusButton(
            label: _isProcessing ? 'Exporting...' : 'Create Full Ecosystem Backup',
            icon: Icons.cloud_download_outlined,
            isFullWidth: true,
            onPressed: _isProcessing ? null : _runExport,
          ),

          if (_backupJson.isNotEmpty) ...[
            const SizedBox(height: FocusSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Exported Archive ($_exportedCount records)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy JSON'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _backupJson));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied full JSON backup to clipboard!')),
                    );
                  },
                ),
              ],
            ),
            Container(
              height: 120,
              padding: FocusSpacing.insetAllSm,
              decoration: BoxDecoration(color: FocusColors.darkSurfaceHigh, borderRadius: BorderRadius.circular(6)),
              child: SingleChildScrollView(
                child: SelectableText(
                  _backupJson.substring(0, _backupJson.length > 500 ? 500 : _backupJson.length) + '\n... (truncated preview)',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
          ],

          const SizedBox(height: FocusSpacing.xl),
          const Divider(),
          const SizedBox(height: FocusSpacing.md),

          // RESTORE SECTION
          const Text('2. Restore Ecosystem from Backup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: FocusSpacing.xs),
          FocusTextField(
            label: 'Paste JSON Archive Here',
            hint: 'Paste entire FocusON backup JSON archive...',
            controller: _importCtrl,
            maxLines: 4,
          ),
          const SizedBox(height: FocusSpacing.sm),
          FocusButton(
            label: _isProcessing ? 'Restoring...' : 'Execute Database Restore',
            icon: Icons.restore,
            variant: FocusButtonVariant.secondary,
            isFullWidth: true,
            onPressed: _isProcessing ? null : _runImport,
          ),

          if (_statusMessage != null) ...[
            const SizedBox(height: FocusSpacing.md),
            Container(
              padding: FocusSpacing.insetAllMd,
              decoration: BoxDecoration(
                color: FocusColors.darkSurfaceHigh,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FocusColors.electricBlue.withOpacity(0.5)),
              ),
              child: Text(
                _statusMessage!,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: FocusColors.electricBlue),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
