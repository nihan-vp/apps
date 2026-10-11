import 'package:flutter/material.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import '../services/lan_drop_server.dart';
import 'dev_utilities_screen.dart';
import 'device_telemetry_screen.dart';
import 'lan_drop_screen.dart';
import 'backup_restore_screen.dart';

class ToolsHomeScreen extends StatefulWidget {
  final FocusDatabase db;
  final LanDropServer lanServer;

  const ToolsHomeScreen({super.key, required this.db, required this.lanServer});

  @override
  State<ToolsHomeScreen> createState() => _ToolsHomeScreenState();
}

class _ToolsHomeScreenState extends State<ToolsHomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FocusON Tools'),
      ),
      body: ListView(
        padding: FocusSpacing.insetAllLg,
        children: [
          FocusTextField(
            label: 'Search Utilities',
            hint: 'Search JSON, Regex, Backup, RAM, Wi-Fi Drop...',
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
          ),
          const SizedBox(height: FocusSpacing.lg),

          // QUICK DEV TOOL TILES
          if (_matches('json') || _matches('format') || _matches('csv'))
            _buildToolCard(
              title: 'JSON Formatter & CSV Converter',
              subtitle: 'Prettify, validate, minify, and export JSON arrays to CSV.',
              icon: Icons.data_object,
              color: FocusColors.electricBlue,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DevUtilitiesScreen(initialTabIndex: 0)),
              ),
            ),

          if (_matches('base64') || _matches('url') || _matches('hash') || _matches('encode'))
            _buildToolCard(
              title: 'Base64 / URL / Hash Encoders',
              subtitle: 'Encode and decode Base64, URL percent-encoding, Hex, MD5, and SHA256.',
              icon: Icons.code,
              color: FocusColors.emeraldGreen,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DevUtilitiesScreen(initialTabIndex: 1)),
              ),
            ),

          if (_matches('regex') || _matches('pattern') || _matches('match'))
            _buildToolCard(
              title: 'Regular Expression Tester',
              subtitle: 'Interactive regex pattern evaluator with group matches.',
              icon: Icons.search,
              color: FocusColors.amberWarning,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DevUtilitiesScreen(initialTabIndex: 2)),
              ),
            ),

          if (_matches('epoch') || _matches('time') || _matches('timestamp'))
            _buildToolCard(
              title: 'Unix Epoch & Timezone Helper',
              subtitle: 'Convert between epoch seconds, ISO-8601, and local time.',
              icon: Icons.schedule,
              color: FocusColors.lavenderPurple,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DevUtilitiesScreen(initialTabIndex: 3)),
              ),
            ),

          if (_matches('uuid') || _matches('guid') || _matches('id'))
            _buildToolCard(
              title: 'UUID v4 Bulk Generator',
              subtitle: 'Generate single or bulk cryptographic UUIDs with instant copy.',
              icon: Icons.tag,
              color: FocusColors.electricCyan,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DevUtilitiesScreen(initialTabIndex: 4)),
              ),
            ),

          if (_matches('word') || _matches('character') || _matches('count') || _matches('reading'))
            _buildToolCard(
              title: 'Word Counter & Reading Time',
              subtitle: 'Detailed character, word, line count, and estimated reading time.',
              icon: Icons.article_outlined,
              color: FocusColors.emeraldGreen,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DevUtilitiesScreen(initialTabIndex: 5)),
              ),
            ),

          if (_matches('diff') || _matches('compare') || _matches('text'))
            _buildToolCard(
              title: 'Text Diff Viewer',
              subtitle: 'Unified diff visualizer for comparing text versions.',
              icon: Icons.difference_outlined,
              color: FocusColors.amberWarning,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DevUtilitiesScreen(initialTabIndex: 6)),
              ),
            ),

          // TELEMETRY
          if (_matches('device') || _matches('ram') || _matches('storage') || _matches('hardware'))
            _buildToolCard(
              title: 'Device Telemetry & Storage Analyzer',
              subtitle: 'System memory, CPU architecture, Android API, and storage allocation.',
              icon: Icons.perm_device_information,
              color: FocusColors.electricBlue,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DeviceTelemetryScreen()),
              ),
            ),

          // LAN DROP
          if (_matches('lan') || _matches('wifi') || _matches('drop') || _matches('transfer') || _matches('http'))
            _buildToolCard(
              title: 'Wi-Fi LAN File Drop Server',
              subtitle: 'Transfer text, code, or files from your computer to phone over local Wi-Fi.',
              icon: Icons.wifi_tethering,
              color: FocusColors.emeraldGreen,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => LanDropScreen(server: widget.lanServer)),
              ),
            ),

          // BACKUP & RESTORE
          if (_matches('backup') || _matches('restore') || _matches('export') || _matches('import'))
            _buildToolCard(
              title: 'Ecosystem Backup & Restore',
              subtitle: 'Export and restore all FocusON SQLite tables across all 6 ecosystem apps.',
              icon: Icons.backup_outlined,
              color: FocusColors.lavenderPurple,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BackupRestoreScreen(db: widget.db)),
              ),
            ),
        ],
      ),
    );
  }

  bool _matches(String keyword) {
    if (_searchQuery.isEmpty) return true;
    return keyword.contains(_searchQuery) || _searchQuery.contains(keyword);
  }

  Widget _buildToolCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FocusSpacing.md),
      child: FocusCard(
        padding: FocusSpacing.insetAllMd,
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(FocusSpacing.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: FocusSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: FocusColors.darkTextMuted),
          ],
        ),
      ),
    );
  }
}
