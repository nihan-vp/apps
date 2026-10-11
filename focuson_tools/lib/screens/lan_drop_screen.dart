import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import '../services/lan_drop_server.dart';

class LanDropScreen extends StatefulWidget {
  final LanDropServer server;

  const LanDropScreen({super.key, required this.server});

  @override
  State<LanDropScreen> createState() => _LanDropScreenState();
}

class _LanDropScreenState extends State<LanDropScreen> {
  static const _channel = MethodChannel('com.focuson.bridge/tools');
  String _ipAddress = '127.0.0.1';
  int _port = 8080;

  @override
  void initState() {
    super.initState();
    _fetchIp();
  }

  void _fetchIp() async {
    try {
      final ip = await _channel.invokeMethod<String>('getLocalIpAddress');
      if (ip != null && ip.isNotEmpty) {
        setState(() => _ipAddress = ip);
      }
    } catch (_) {
      setState(() => _ipAddress = '192.168.1.100');
    }
  }

  void _toggleServer() async {
    if (widget.server.isRunning) {
      await widget.server.stop();
    } else {
      await widget.server.start(port: _port, localIp: _ipAddress);
    }
    setState(() {});
  }

  void _copyUrl() {
    final url = 'http://$_ipAddress:$_port';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied $url to clipboard!'), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = widget.server.isRunning;
    final drops = widget.server.receivedNotes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi LAN File Drop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear Drops',
            onPressed: drops.isEmpty ? null : () => widget.server.clearNotes(),
          ),
        ],
      ),
      body: ListView(
        padding: FocusSpacing.insetAllLg,
        children: [
          FocusCard(
            borderColor: isRunning ? FocusColors.emeraldGreen : FocusColors.darkBorder,
            padding: FocusSpacing.insetAllMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRunning ? FocusColors.emeraldGreen : FocusColors.coralDanger,
                      ),
                    ),
                    const SizedBox(width: FocusSpacing.sm),
                    Text(
                      isRunning ? 'LAN Server Running' : 'LAN Server Stopped',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isRunning ? FocusColors.emeraldGreen : FocusColors.coralDanger),
                    ),
                    const Spacer(),
                    FocusButton(
                      label: isRunning ? 'Stop Server' : 'Start Server',
                      variant: isRunning ? FocusButtonVariant.secondary : FocusButtonVariant.primary,
                      height: 32,
                      onPressed: _toggleServer,
                    ),
                  ],
                ),
                if (isRunning) ...[
                  const SizedBox(height: FocusSpacing.md),
                  const Text('Open this link on any PC, Mac, or phone on your Wi-Fi:', style: TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary)),
                  const SizedBox(height: FocusSpacing.xs),
                  GestureDetector(
                    onTap: _copyUrl,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: FocusColors.darkSurfaceHigh,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: FocusColors.electricBlue.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              'http://$_ipAddress:$_port',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FocusColors.electricBlue),
                            ),
                          ),
                          const Icon(Icons.copy, size: 18, color: FocusColors.electricBlue),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: FocusSpacing.lg),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Received Snippets (${drops.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              if (drops.isNotEmpty)
                TextButton(
                  onPressed: () => widget.server.clearNotes(),
                  child: const Text('Clear', style: TextStyle(color: FocusColors.coralDanger)),
                ),
            ],
          ),
          const SizedBox(height: FocusSpacing.sm),

          if (drops.isEmpty)
            const FocusEmptyState(
              icon: Icons.wifi_tethering,
              title: 'No Drops Received',
              message: 'Start the server and send text or code from your computer browser via Wi-Fi.',
            ),

          ...drops.map((drop) => Container(
            margin: const EdgeInsets.only(bottom: FocusSpacing.sm),
            padding: FocusSpacing.insetAllMd,
            decoration: BoxDecoration(
              color: FocusColors.darkSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FocusColors.darkBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SelectableText(
                    drop,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copy',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: drop));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied snippet!'), duration: Duration(seconds: 1)),
                    );
                  },
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
