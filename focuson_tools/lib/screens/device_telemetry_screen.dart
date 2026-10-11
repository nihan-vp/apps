import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focuson_design_system/focuson_design_system.dart';

class DeviceTelemetryScreen extends StatefulWidget {
  const DeviceTelemetryScreen({super.key});

  @override
  State<DeviceTelemetryScreen> createState() => _DeviceTelemetryScreenState();
}

class _DeviceTelemetryScreenState extends State<DeviceTelemetryScreen> {
  static const _channel = MethodChannel('com.focuson.bridge/tools');

  Map<String, dynamic> _deviceInfo = {};
  Map<String, dynamic> _storageInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTelemetry();
  }

  void _loadTelemetry() async {
    setState(() => _isLoading = true);
    try {
      final dev = await _channel.invokeMapMethod<String, dynamic>('getDeviceInfo');
      final stor = await _channel.invokeMapMethod<String, dynamic>('getStorageInfo');
      setState(() {
        _deviceInfo = dev ?? {};
        _storageInfo = stor ?? {};
        _isLoading = false;
      });
    } catch (_) {
      // Fallback telemetry for testing / non-Android targets
      setState(() {
        _deviceInfo = {
          'manufacturer': 'Google',
          'model': 'Pixel 8 Pro (Simulated / Local)',
          'androidVersion': '14',
          'sdkInt': 34,
          'board': 'shiba',
          'cpuAbi': 'arm64-v8a',
          'totalRamBytes': 12884901888,
          'availRamBytes': 6442450944,
          'lowMemory': false,
        };
        _storageInfo = {
          'totalBytes': 128000000000,
          'freeBytes': 45000000000,
          'usedBytes': 83000000000,
          'path': '/data/user/0',
        };
        _isLoading = false;
      });
    }
  }

  String _formatBytes(dynamic bytes) {
    if (bytes == null) return '0 B';
    final n = (bytes as num).toDouble();
    if (n >= 1024 * 1024 * 1024) return '${(n / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    if (n >= 1024 * 1024) return '${(n / (1024 * 1024)).toStringAsFixed(1)} MB';
    if (n >= 1024) return '${(n / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device & Storage Telemetry'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTelemetry),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: FocusSpacing.insetAllLg,
              children: [
                // STORAGE CARD
                FocusCard(
                  padding: FocusSpacing.insetAllMd,
                  borderColor: FocusColors.electricBlue.withOpacity(0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.storage_outlined, color: FocusColors.electricBlue, size: 20),
                          SizedBox(width: FocusSpacing.xs),
                          Text('Internal Storage Analyzer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: FocusSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Used: ${_formatBytes(_storageInfo['usedBytes'])}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Free: ${_formatBytes(_storageInfo['freeBytes'])}', style: const TextStyle(color: FocusColors.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: FocusSpacing.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_storageInfo['totalBytes'] != null && (_storageInfo['totalBytes'] as num) > 0)
                              ? ((_storageInfo['usedBytes'] as num).toDouble() / (_storageInfo['totalBytes'] as num).toDouble())
                              : 0.5,
                          backgroundColor: FocusColors.darkSurfaceHigh,
                          color: FocusColors.electricBlue,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: FocusSpacing.xs),
                      Text('Total Space: ${_formatBytes(_storageInfo['totalBytes'])}', style: const TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: FocusSpacing.md),

                // RAM & MEMORY CARD
                FocusCard(
                  padding: FocusSpacing.insetAllMd,
                  borderColor: FocusColors.emeraldGreen.withOpacity(0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.memory, color: FocusColors.emeraldGreen, size: 20),
                          SizedBox(width: FocusSpacing.xs),
                          Text('RAM Memory Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: FocusSpacing.sm),
                      _buildInfoRow('Total System RAM', _formatBytes(_deviceInfo['totalRamBytes'])),
                      _buildInfoRow('Available RAM', _formatBytes(_deviceInfo['availRamBytes'])),
                      _buildInfoRow('Low Memory Warning', _deviceInfo['lowMemory'] == true ? 'YES' : 'NO (Healthy)'),
                    ],
                  ),
                ),
                const SizedBox(height: FocusSpacing.md),

                // HARDWARE DETAILS
                FocusCard(
                  padding: FocusSpacing.insetAllMd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.phone_android, color: FocusColors.lavenderPurple, size: 20),
                          SizedBox(width: FocusSpacing.xs),
                          Text('Hardware & Platform Identity', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: FocusSpacing.sm),
                      _buildInfoRow('Manufacturer', '${_deviceInfo['manufacturer'] ?? "Unknown"}'),
                      _buildInfoRow('Model', '${_deviceInfo['model'] ?? "Unknown"}'),
                      _buildInfoRow('Android Release', 'Android ${_deviceInfo['androidVersion'] ?? "?"} (API ${_deviceInfo['sdkInt'] ?? "?"})'),
                      _buildInfoRow('Motherboard', '${_deviceInfo['board'] ?? "Unknown"}'),
                      _buildInfoRow('CPU Architecture', '${_deviceInfo['cpuAbi'] ?? "Unknown"}'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: FocusColors.darkTextSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
