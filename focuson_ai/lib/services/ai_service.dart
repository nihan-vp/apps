import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_ai_core/focuson_ai_core.dart';

enum AIProviderMode {
  unconfigured,
  localDeterministic,
  ollamaLocal,
  cloudOpenAI,
}

class AIService extends ChangeNotifier {
  final FocusDatabase db;

  AIProviderMode _mode = AIProviderMode.localDeterministic;
  String _endpoint = 'http://10.0.2.2:11434'; // Default Android emulator host for Ollama
  String _apiKey = '';
  String _modelName = 'llama3.2:1b';
  bool _allowTelemetry = false;

  AIProvider? _activeProvider;

  AIService({required this.db}) {
    _init();
  }

  AIProviderMode get mode => _mode;
  String get endpoint => _endpoint;
  String get apiKey => _apiKey;
  String get modelName => _modelName;
  bool get allowTelemetry => _allowTelemetry;
  AIProvider? get activeProvider => _activeProvider;
  bool get isConfigured => _mode != AIProviderMode.unconfigured && _activeProvider != null;

  void _init() {
    _refreshProvider();
  }

  void _refreshProvider() {
    switch (_mode) {
      case AIProviderMode.unconfigured:
        _activeProvider = null;
        break;
      case AIProviderMode.localDeterministic:
        _activeProvider = OfflineRuleBasedProvider();
        break;
      case AIProviderMode.ollamaLocal:
        _activeProvider = HttpCloudAIProvider(
          endpoint: _endpoint.endsWith('/v1/chat/completions')
              ? _endpoint
              : '$_endpoint/v1/chat/completions',
          apiKey: 'ollama', // Ollama accepts any bearer token
          modelName: _modelName.isEmpty ? 'llama3.2:1b' : _modelName,
        );
        break;
      case AIProviderMode.cloudOpenAI:
        _activeProvider = HttpCloudAIProvider(
          endpoint: _endpoint.isEmpty ? 'https://api.openai.com/v1/chat/completions' : _endpoint,
          apiKey: _apiKey,
          modelName: _modelName.isEmpty ? 'gpt-4o-mini' : _modelName,
        );
        break;
    }
    notifyListeners();
  }

  void updateConfig({
    required AIProviderMode mode,
    required String endpoint,
    required String apiKey,
    required String modelName,
    required bool allowTelemetry,
  }) {
    _mode = mode;
    _endpoint = endpoint.trim();
    _apiKey = apiKey.trim();
    _modelName = modelName.trim();
    _allowTelemetry = allowTelemetry;
    _refreshProvider();
  }

  Future<Task> parseTask(String text) async {
    _checkConfigured();
    return await _activeProvider!.parseTaskFromText(text);
  }

  Future<List<Subtask>> breakdownTask(Task task) async {
    _checkConfigured();
    return await _activeProvider!.breakdownTask(task);
  }

  Future<List<DailyPlanBlock>> generateDailyPlan(List<Task> pendingTasks, int hours) async {
    _checkConfigured();
    return await _activeProvider!.generateDailyPlan(pendingTasks, hours);
  }

  Future<List<String>> generateStudyPlan(Subject subject, Exam exam, List<SyllabusTopic> topics) async {
    _checkConfigured();
    return await _activeProvider!.generateStudyPlan(subject, exam, topics);
  }

  Future<AutomationRule> generateWorkflow(String description) async {
    _checkConfigured();
    return await _activeProvider!.generateAutomationWorkflow(description);
  }

  Future<String> explainUsage(List<AppUsageRecord> records) async {
    _checkConfigured();
    return await _activeProvider!.explainUsagePatterns(records);
  }

  void _checkConfigured() {
    if (_mode == AIProviderMode.unconfigured || _activeProvider == null) {
      throw StateError('AI Provider is not configured. Please select a provider in AI Settings.');
    }
  }
}
