import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import '../utils/formatters.dart';

class DevUtilitiesScreen extends StatefulWidget {
  final int initialTabIndex;

  const DevUtilitiesScreen({super.key, this.initialTabIndex = 0});

  @override
  State<DevUtilitiesScreen> createState() => _DevUtilitiesScreenState();
}

class _DevUtilitiesScreenState extends State<DevUtilitiesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // JSON Tab
  final TextEditingController _jsonInputCtrl = TextEditingController(text: '{"name":"FocusON","type":"ecosystem","apps":6,"offline":true}');
  String _jsonOutput = '';
  String? _jsonError;

  // Encoders Tab
  final TextEditingController _encodeInputCtrl = TextEditingController(text: 'Hello FocusON Ecosystem!');
  String _encodedResult = '';
  String _activeCodec = 'Base64';

  // Regex Tab
  final TextEditingController _regexPatternCtrl = TextEditingController(text: r'#\w+');
  final TextEditingController _regexTextCtrl = TextEditingController(text: 'Review chapter 4 #biology and finish #homework by 5pm');
  List<String> _regexMatches = [];

  // Timestamp Tab
  final TextEditingController _epochInputCtrl = TextEditingController(text: '1728648000');
  String _convertedDateTime = '';

  // UUID Tab
  List<String> _generatedUuids = [];
  int _uuidCount = 5;

  // Word Count Tab
  final TextEditingController _wordTextCtrl = TextEditingController(text: 'FocusON is a high-performance, privacy-first Android ecosystem consisting of six interoperable applications built without bloatware, advertisements, or data mining.');
  Map<String, dynamic> _textStats = {};

  // Diff Tab
  final TextEditingController _diffOldCtrl = TextEditingController(text: 'FocusON Launcher\nFocusON Control\nFocusON Planner');
  final TextEditingController _diffNewCtrl = TextEditingController(text: 'FocusON Launcher\nFocusON Control v2\nFocusON Planner\nFocusON Automate');
  List<DiffLine> _diffLines = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this, initialIndex: widget.initialTabIndex);
    _formatJson();
    _runCodec();
    _testRegex();
    _convertEpoch();
    _generateUuids();
    _analyzeWords();
    _computeDiff();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _jsonInputCtrl.dispose();
    _encodeInputCtrl.dispose();
    _regexPatternCtrl.dispose();
    _regexTextCtrl.dispose();
    _epochInputCtrl.dispose();
    _wordTextCtrl.dispose();
    _diffOldCtrl.dispose();
    _diffNewCtrl.dispose();
    super.dispose();
  }

  void _formatJson() {
    setState(() {
      try {
        _jsonOutput = DevFormatters.formatJson(_jsonInputCtrl.text);
        _jsonError = null;
      } catch (e) {
        _jsonError = e.toString();
      }
    });
  }

  void _runCodec() {
    setState(() {
      try {
        final text = _encodeInputCtrl.text;
        switch (_activeCodec) {
          case 'Base64':
            _encodedResult = DevFormatters.base64EncodeText(text);
            break;
          case 'Base64 Decode':
            _encodedResult = DevFormatters.base64DecodeText(text);
            break;
          case 'URL Encode':
            _encodedResult = DevFormatters.urlEncodeText(text);
            break;
          case 'URL Decode':
            _encodedResult = DevFormatters.urlDecodeText(text);
            break;
          case 'Hex Encode':
            _encodedResult = DevFormatters.hexEncodeText(text);
            break;
          case 'MD5':
            _encodedResult = DevFormatters.md5Hash(text);
            break;
          case 'SHA256':
            _encodedResult = DevFormatters.sha256Hash(text);
            break;
        }
      } catch (e) {
        _encodedResult = 'Error: $e';
      }
    });
  }

  void _testRegex() {
    setState(() {
      try {
        final reg = RegExp(_regexPatternCtrl.text);
        final matches = reg.allMatches(_regexTextCtrl.text);
        _regexMatches = matches.map((m) => m.group(0) ?? '').toList();
      } catch (e) {
        _regexMatches = ['Regex Error: $e'];
      }
    });
  }

  void _convertEpoch() {
    setState(() {
      final sec = int.tryParse(_epochInputCtrl.text);
      if (sec != null) {
        final dt = DevFormatters.epochToDateTime(sec);
        _convertedDateTime = 'UTC: ${dt.toUtc().toString()}\nLocal: ${dt.toLocal().toString()}';
      } else {
        _convertedDateTime = 'Invalid epoch timestamp';
      }
    });
  }

  void _generateUuids() {
    setState(() {
      _generatedUuids = List.generate(_uuidCount, (_) => FocusUuid.v4());
    });
  }

  void _analyzeWords() {
    setState(() {
      _textStats = DevFormatters.analyzeText(_wordTextCtrl.text);
    });
  }

  void _computeDiff() {
    setState(() {
      _diffLines = DevFormatters.computeDiff(_diffOldCtrl.text, _diffNewCtrl.text);
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Utilities'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'JSON'),
            Tab(text: 'Encoders'),
            Tab(text: 'Regex'),
            Tab(text: 'Epoch'),
            Tab(text: 'UUID'),
            Tab(text: 'Word Count'),
            Tab(text: 'Diff'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // JSON TAB
          ListView(
            padding: FocusSpacing.insetAllMd,
            children: [
              FocusTextField(label: 'JSON Input', controller: _jsonInputCtrl, maxLines: 6),
              const SizedBox(height: FocusSpacing.sm),
              Row(
                children: [
                  FocusButton(label: 'Format / Prettify', height: 36, onPressed: _formatJson),
                  const SizedBox(width: FocusSpacing.sm),
                  FocusButton(
                    label: 'Minify',
                    height: 36,
                    variant: FocusButtonVariant.secondary,
                    onPressed: () {
                      setState(() {
                        try {
                          _jsonOutput = DevFormatters.minifyJson(_jsonInputCtrl.text);
                          _jsonError = null;
                        } catch (e) {
                          _jsonError = e.toString();
                        }
                      });
                    },
                  ),
                  const SizedBox(width: FocusSpacing.sm),
                  FocusButton(
                    label: 'To CSV',
                    height: 36,
                    variant: FocusButtonVariant.secondary,
                    onPressed: () {
                      setState(() {
                        try {
                          _jsonOutput = DevFormatters.jsonToCsv(_jsonInputCtrl.text);
                          _jsonError = null;
                        } catch (e) {
                          _jsonError = e.toString();
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: FocusSpacing.md),
              if (_jsonError != null)
                Text(_jsonError!, style: const TextStyle(color: FocusColors.coralDanger, fontWeight: FontWeight.bold)),
              if (_jsonOutput.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Result', style: TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: () => _copyToClipboard(_jsonOutput)),
                  ],
                ),
                Container(
                  padding: FocusSpacing.insetAllMd,
                  decoration: BoxDecoration(color: FocusColors.darkSurfaceHigh, borderRadius: BorderRadius.circular(8)),
                  child: SelectableText(_jsonOutput, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ),
              ],
            ],
          ),

          // ENCODERS TAB
          ListView(
            padding: FocusSpacing.insetAllMd,
            children: [
              FocusTextField(label: 'Input String', controller: _encodeInputCtrl, maxLines: 4),
              const SizedBox(height: FocusSpacing.sm),
              Wrap(
                spacing: FocusSpacing.xs,
                runSpacing: FocusSpacing.xs,
                children: ['Base64', 'Base64 Decode', 'URL Encode', 'URL Decode', 'Hex Encode', 'MD5', 'SHA256'].map((codec) {
                  return ChoiceChip(
                    label: Text(codec),
                    selected: _activeCodec == codec,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _activeCodec = codec);
                        _runCodec();
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: FocusSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Output ($_activeCodec)', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: () => _copyToClipboard(_encodedResult)),
                ],
              ),
              Container(
                padding: FocusSpacing.insetAllMd,
                decoration: BoxDecoration(color: FocusColors.darkSurfaceHigh, borderRadius: BorderRadius.circular(8)),
                child: SelectableText(_encodedResult, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: FocusColors.electricBlue)),
              ),
            ],
          ),

          // REGEX TAB
          ListView(
            padding: FocusSpacing.insetAllMd,
            children: [
              FocusTextField(label: 'Regex Pattern', hint: r'#\w+ or \d{2}:\d{2}', controller: _regexPatternCtrl),
              const SizedBox(height: FocusSpacing.sm),
              FocusTextField(label: 'Test String', controller: _regexTextCtrl, maxLines: 3),
              const SizedBox(height: FocusSpacing.sm),
              FocusButton(label: 'Evaluate Matches', height: 36, onPressed: _testRegex),
              const SizedBox(height: FocusSpacing.md),
              Text('Matches Found (${_regexMatches.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: FocusSpacing.xs),
              ..._regexMatches.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: FocusColors.darkSurfaceHigh, borderRadius: BorderRadius.circular(4)),
                child: Text(m, style: const TextStyle(fontFamily: 'monospace', color: FocusColors.emeraldGreen)),
              )),
            ],
          ),

          // EPOCH TAB
          ListView(
            padding: FocusSpacing.insetAllMd,
            children: [
              FocusTextField(label: 'Unix Epoch (Seconds)', controller: _epochInputCtrl),
              const SizedBox(height: FocusSpacing.sm),
              Row(
                children: [
                  FocusButton(label: 'Convert', height: 36, onPressed: _convertEpoch),
                  const SizedBox(width: FocusSpacing.sm),
                  FocusButton(
                    label: 'Set to Now',
                    height: 36,
                    variant: FocusButtonVariant.secondary,
                    onPressed: () {
                      _epochInputCtrl.text = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
                      _convertEpoch();
                    },
                  ),
                ],
              ),
              const SizedBox(height: FocusSpacing.md),
              Container(
                padding: FocusSpacing.insetAllMd,
                decoration: BoxDecoration(color: FocusColors.darkSurfaceHigh, borderRadius: BorderRadius.circular(8)),
                child: SelectableText(_convertedDateTime, style: const TextStyle(fontSize: 14, height: 1.5)),
              ),
            ],
          ),

          // UUID TAB
          ListView(
            padding: FocusSpacing.insetAllMd,
            children: [
              Row(
                children: [
                  const Text('Count: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<int>(
                    value: _uuidCount,
                    dropdownColor: FocusColors.darkSurfaceHigh,
                    items: [1, 5, 10, 20].map((c) => DropdownMenuItem(value: c, child: Text('$c'))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _uuidCount = val);
                        _generateUuids();
                      }
                    },
                  ),
                  const Spacer(),
                  FocusButton(label: 'Generate', height: 36, onPressed: _generateUuids),
                ],
              ),
              const SizedBox(height: FocusSpacing.md),
              ..._generatedUuids.map((id) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: FocusSpacing.insetAllSm,
                decoration: BoxDecoration(color: FocusColors.darkSurfaceHigh, borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: [
                    Expanded(child: SelectableText(id, style: const TextStyle(fontFamily: 'monospace', fontSize: 13))),
                    IconButton(icon: const Icon(Icons.copy, size: 16), onPressed: () => _copyToClipboard(id)),
                  ],
                ),
              )),
            ],
          ),

          // WORD COUNT TAB
          ListView(
            padding: FocusSpacing.insetAllMd,
            children: [
              FocusTextField(label: 'Text Analysis Scratchpad', controller: _wordTextCtrl, maxLines: 6),
              const SizedBox(height: FocusSpacing.sm),
              FocusButton(label: 'Analyze', height: 36, onPressed: _analyzeWords),
              const SizedBox(height: FocusSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: FocusCard(
                      padding: FocusSpacing.insetAllMd,
                      child: Column(
                        children: [
                          Text('${_textStats['words'] ?? 0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: FocusColors.electricBlue)),
                          const Text('Words', style: TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: FocusSpacing.sm),
                  Expanded(
                    child: FocusCard(
                      padding: FocusSpacing.insetAllMd,
                      child: Column(
                        children: [
                          Text('${_textStats['characters'] ?? 0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: FocusColors.emeraldGreen)),
                          const Text('Characters', style: TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FocusSpacing.sm),
              FocusCard(
                padding: FocusSpacing.insetAllMd,
                child: Text('Estimated Reading Time: ~${_textStats['readingTimeMinutes'] ?? 0} min (at 200 WPM)', style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),

          // DIFF TAB
          ListView(
            padding: FocusSpacing.insetAllMd,
            children: [
              FocusTextField(label: 'Original Text', controller: _diffOldCtrl, maxLines: 4),
              const SizedBox(height: FocusSpacing.sm),
              FocusTextField(label: 'Modified Text', controller: _diffNewCtrl, maxLines: 4),
              const SizedBox(height: FocusSpacing.sm),
              FocusButton(label: 'Compute Diff', height: 36, onPressed: _computeDiff),
              const SizedBox(height: FocusSpacing.md),
              const Text('Unified Diff Comparison', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: FocusSpacing.xs),
              Container(
                padding: FocusSpacing.insetAllMd,
                decoration: BoxDecoration(color: FocusColors.darkSurfaceHigh, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _diffLines.map((line) {
                    Color color = Colors.white70;
                    String prefix = '  ';
                    if (line.type == DiffType.added) {
                      color = FocusColors.emeraldGreen;
                      prefix = '+ ';
                    } else if (line.type == DiffType.removed) {
                      color = FocusColors.coralDanger;
                      prefix = '- ';
                    }
                    return Text('$prefix${line.text}', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: color));
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
