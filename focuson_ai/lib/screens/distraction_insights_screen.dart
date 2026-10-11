import 'package:flutter/material.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import '../services/ai_service.dart';
import 'provider_settings_screen.dart';

class DistractionInsightsScreen extends StatefulWidget {
  final AIService aiService;
  final FocusDatabase db;

  const DistractionInsightsScreen({super.key, required this.aiService, required this.db});

  @override
  State<DistractionInsightsScreen> createState() => _DistractionInsightsScreenState();
}

class _DistractionInsightsScreenState extends State<DistractionInsightsScreen> {
  bool _isLoading = false;
  String? _insights;
  String? _error;

  void _generateInsights() async {
    if (!widget.aiService.isConfigured) {
      setState(() => _error = 'AI Provider is not configured. Please choose a provider in Settings.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sampleRecords = [
        AppUsageRecord(
          packageName: 'com.instagram.android',
          appName: 'Instagram',
          durationSeconds: 4200,
          launchCount: 18,
          date: DateTime.now(),
        ),
        AppUsageRecord(
          packageName: 'com.google.android.youtube',
          appName: 'YouTube',
          durationSeconds: 3100,
          launchCount: 8,
          date: DateTime.now(),
        ),
        AppUsageRecord(
          packageName: 'com.reddit.frontpage',
          appName: 'Reddit',
          durationSeconds: 1900,
          launchCount: 12,
          date: DateTime.now(),
        ),
      ];

      final result = await widget.aiService.explainUsage(sampleRecords);
      setState(() {
        _insights = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Distraction Analysis & Insights'),
      ),
      body: ListView(
        padding: FocusSpacing.insetAllLg,
        children: [
          FocusCard(
            borderColor: FocusColors.amberWarning.withOpacity(0.4),
            padding: FocusSpacing.insetAllMd,
            child: const Row(
              children: [
                Icon(Icons.query_stats, color: FocusColors.amberWarning, size: 28),
                SizedBox(width: FocusSpacing.md),
                Expanded(
                  child: Text(
                    'AI analyzes local usage stats to detect unconscious phone-checking habits and suggests friction intervals.',
                    style: TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: FocusSpacing.lg),

          FocusButton(
            label: _isLoading ? 'Synthesizing Usage Data...' : 'Analyze Today\'s Usage Patterns',
            isFullWidth: true,
            icon: Icons.psychology_outlined,
            onPressed: _isLoading ? null : _generateInsights,
          ),
          const SizedBox(height: FocusSpacing.lg),

          if (_error != null)
            FocusCard(
              borderColor: FocusColors.coralDanger.withOpacity(0.5),
              padding: FocusSpacing.insetAllMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Provider Not Configured', style: TextStyle(fontWeight: FontWeight.bold, color: FocusColors.coralDanger)),
                  const SizedBox(height: FocusSpacing.xs),
                  Text(_error!, style: const TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary)),
                  const SizedBox(height: FocusSpacing.sm),
                  FocusButton(
                    label: 'Configure AI Provider',
                    variant: FocusButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ProviderSettingsScreen(aiService: widget.aiService)),
                    ),
                  ),
                ],
              ),
            ),

          if (_insights != null)
            FocusCard(
              borderColor: FocusColors.electricBlue.withOpacity(0.5),
              padding: FocusSpacing.insetAllLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: FocusColors.amberWarning, size: 20),
                      SizedBox(width: FocusSpacing.xs),
                      Text('Usage Synthesis & Guidance', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: FocusSpacing.md),
                  Text(
                    _insights!,
                    style: const TextStyle(fontSize: 13, height: 1.5, color: FocusColors.darkTextPrimary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
