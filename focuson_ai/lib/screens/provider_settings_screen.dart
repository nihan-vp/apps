import 'package:flutter/material.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import '../services/ai_service.dart';

class ProviderSettingsScreen extends StatefulWidget {
  final AIService aiService;

  const ProviderSettingsScreen({super.key, required this.aiService});

  @override
  State<ProviderSettingsScreen> createState() => _ProviderSettingsScreenState();
}

class _ProviderSettingsScreenState extends State<ProviderSettingsScreen> {
  late AIProviderMode _selectedMode;
  late final TextEditingController _endpointCtrl;
  late final TextEditingController _apiKeyCtrl;
  late final TextEditingController _modelCtrl;
  late bool _allowTelemetry;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.aiService.mode;
    _endpointCtrl = TextEditingController(text: widget.aiService.endpoint);
    _apiKeyCtrl = TextEditingController(text: widget.aiService.apiKey);
    _modelCtrl = TextEditingController(text: widget.aiService.modelName);
    _allowTelemetry = widget.aiService.allowTelemetry;
  }

  @override
  void dispose() {
    _endpointCtrl.dispose();
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  void _saveSettings() {
    widget.aiService.updateConfig(
      mode: _selectedMode,
      endpoint: _endpointCtrl.text,
      apiKey: _apiKeyCtrl.text,
      modelName: _modelCtrl.text,
      allowTelemetry: _allowTelemetry,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI Provider settings updated.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Provider & Privacy Settings'),
      ),
      body: ListView(
        padding: FocusSpacing.insetAllLg,
        children: [
          // Privacy Banner
          FocusCard(
            borderColor: FocusColors.emeraldGreen.withOpacity(0.5),
            padding: FocusSpacing.insetAllMd,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_outline, color: FocusColors.emeraldGreen, size: 20),
                    SizedBox(width: FocusSpacing.xs),
                    Text('Zero-Retention & Privacy Guarantee', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: FocusColors.emeraldGreen)),
                  ],
                ),
                SizedBox(height: FocusSpacing.xs),
                Text(
                  'FocusON never sells user data, retains chat history on central servers, or trains models on your notes. When using Local Inference or Ollama, zero data ever leaves your device or LAN.',
                  style: TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: FocusSpacing.lg),

          const Text('Select AI Provider Mode', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: FocusSpacing.sm),

          RadioListTile<AIProviderMode>(
            title: const Text('Unconfigured (Disabled)'),
            subtitle: const Text('Strictly disables all AI queries and never returns fabricated responses.'),
            value: AIProviderMode.unconfigured,
            groupValue: _selectedMode,
            onChanged: (val) => setState(() => _selectedMode = val!),
          ),

          RadioListTile<AIProviderMode>(
            title: const Text('Local Deterministic (100% Offline)'),
            subtitle: const Text('Fast on-device rule matching, regex entity extraction, and knapsack schedule planner. Requires no network access or external server.'),
            value: AIProviderMode.localDeterministic,
            groupValue: _selectedMode,
            onChanged: (val) => setState(() => _selectedMode = val!),
          ),

          RadioListTile<AIProviderMode>(
            title: const Text('Ollama / Local LLM (LAN)'),
            subtitle: const Text('Connects to an Ollama server running locally or on your home network.'),
            value: AIProviderMode.ollamaLocal,
            groupValue: _selectedMode,
            onChanged: (val) => setState(() => _selectedMode = val!),
          ),

          RadioListTile<AIProviderMode>(
            title: const Text('Cloud OpenAI / Compatible API'),
            subtitle: const Text('Direct API calls to OpenAI, Groq, or Anthropic compatible endpoint using your own personal API key.'),
            value: AIProviderMode.cloudOpenAI,
            groupValue: _selectedMode,
            onChanged: (val) => setState(() => _selectedMode = val!),
          ),

          const SizedBox(height: FocusSpacing.md),

          // Conditional Config Fields
          if (_selectedMode == AIProviderMode.ollamaLocal) ...[
            FocusCard(
              padding: FocusSpacing.insetAllMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ollama Setup Guide', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: FocusColors.electricBlue)),
                  const SizedBox(height: FocusSpacing.xs),
                  const Text(
                    '1. On your PC, run: "ollama run llama3.2:1b"\n'
                    '2. Ensure OLLAMA_HOST=0.0.0.0 is set so mobile devices on your Wi-Fi can reach it.\n'
                    '3. Enter your PC IP address below (e.g. http://192.168.1.50:11434).',
                    style: TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary, height: 1.4),
                  ),
                  const SizedBox(height: FocusSpacing.md),
                  FocusTextField(label: 'Ollama Base URL', hint: 'http://192.168.1.x:11434', controller: _endpointCtrl),
                  const SizedBox(height: FocusSpacing.sm),
                  FocusTextField(label: 'Model Name', hint: 'llama3.2:1b or mistral', controller: _modelCtrl),
                ],
              ),
            ),
          ],

          if (_selectedMode == AIProviderMode.cloudOpenAI) ...[
            FocusCard(
              padding: FocusSpacing.insetAllMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cloud Provider Credentials', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: FocusColors.lavenderPurple)),
                  const SizedBox(height: FocusSpacing.xs),
                  const Text('API keys are saved in local encrypted device storage and only transmitted directly to your specified endpoint.',
                    style: TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary),
                  ),
                  const SizedBox(height: FocusSpacing.md),
                  FocusTextField(label: 'Endpoint URL', hint: 'https://api.openai.com/v1/chat/completions', controller: _endpointCtrl),
                  const SizedBox(height: FocusSpacing.sm),
                  FocusTextField(label: 'Model Name', hint: 'gpt-4o-mini', controller: _modelCtrl),
                  const SizedBox(height: FocusSpacing.sm),
                  FocusTextField(label: 'API Key', hint: 'sk-...', controller: _apiKeyCtrl, obscureText: true),
                ],
              ),
            ),
          ],

          const SizedBox(height: FocusSpacing.md),

          // Telemetry Toggle
          SwitchListTile(
            title: const Text('Allow Cloud Telemetry'),
            subtitle: const Text('Default is OFF. When disabled, zero usage statistics or diagnostics are sent outside the device.'),
            value: _allowTelemetry,
            activeColor: FocusColors.electricBlue,
            onChanged: (val) => setState(() => _allowTelemetry = val),
          ),

          const SizedBox(height: FocusSpacing.lg),

          FocusButton(
            label: 'Save Configuration',
            isFullWidth: true,
            onPressed: _saveSettings,
          ),
        ],
      ),
    );
  }
}
