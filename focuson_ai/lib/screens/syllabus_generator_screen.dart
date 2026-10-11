import 'package:flutter/material.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';
import '../services/ai_service.dart';
import 'provider_settings_screen.dart';

class SyllabusGeneratorScreen extends StatefulWidget {
  final AIService aiService;
  final FocusDatabase db;

  const SyllabusGeneratorScreen({super.key, required this.aiService, required this.db});

  @override
  State<SyllabusGeneratorScreen> createState() => _SyllabusGeneratorScreenState();
}

class _SyllabusGeneratorScreenState extends State<SyllabusGeneratorScreen> {
  final TextEditingController _subjectCtrl = TextEditingController(text: 'Computer Architecture');
  final TextEditingController _examCtrl = TextEditingController(text: 'Midterm Examination');
  int _daysUntilExam = 7;
  bool _isLoading = false;
  List<String> _planSteps = [];
  String? _error;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _examCtrl.dispose();
    super.dispose();
  }

  void _runSyllabusGenerator() async {
    if (!widget.aiService.isConfigured) {
      setState(() => _error = 'AI Provider is not configured. Please choose a provider in Settings.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subject = Subject(name: _subjectCtrl.text.trim());
      final exam = Exam(
        subjectId: subject.id,
        title: _examCtrl.text.trim(),
        examDate: DateTime.now().add(Duration(days: _daysUntilExam)),
      );

      final topics = [
        SyllabusTopic(subjectId: subject.id, title: 'Instruction Set Architecture (RISC-V)', masteryLevel: 0),
        SyllabusTopic(subjectId: subject.id, title: 'Pipeline Hazards & Branch Prediction', masteryLevel: 1),
        SyllabusTopic(subjectId: subject.id, title: 'Cache Hierarchy & Memory Locality', masteryLevel: 0),
        SyllabusTopic(subjectId: subject.id, title: 'Virtual Memory & Page Tables', masteryLevel: 1),
      ];

      final steps = await widget.aiService.generateStudyPlan(subject, exam, topics);
      setState(() {
        _planSteps = steps;
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
        title: const Text('Study Syllabus Generator'),
      ),
      body: ListView(
        padding: FocusSpacing.insetAllLg,
        children: [
          FocusTextField(label: 'Subject Name', controller: _subjectCtrl),
          const SizedBox(height: FocusSpacing.sm),
          FocusTextField(label: 'Exam Title', controller: _examCtrl),
          const SizedBox(height: FocusSpacing.md),
          Text('Days Until Exam: $_daysUntilExam days', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Slider(
            value: _daysUntilExam.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            activeColor: FocusColors.emeraldGreen,
            onChanged: (val) => setState(() => _daysUntilExam = val.toInt()),
          ),
          const SizedBox(height: FocusSpacing.md),
          FocusButton(
            label: _isLoading ? 'Generating Revision Roadmap...' : 'Generate Spaced Revision Plan',
            isFullWidth: true,
            icon: Icons.school_outlined,
            onPressed: _isLoading ? null : _runSyllabusGenerator,
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

          if (_planSteps.isNotEmpty) ...[
            const Text('Personalized Revision Plan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: FocusSpacing.sm),
            ..._planSteps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: FocusSpacing.sm),
              child: FocusCard(
                padding: FocusSpacing.insetAllMd,
                borderColor: FocusColors.emeraldGreen.withOpacity(0.3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, color: FocusColors.emeraldGreen, size: 20),
                    const SizedBox(width: FocusSpacing.sm),
                    Expanded(
                      child: Text(step, style: const TextStyle(fontSize: 13, height: 1.4)),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }
}
