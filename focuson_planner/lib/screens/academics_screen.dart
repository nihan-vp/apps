import 'package:flutter/material.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';

class AcademicsScreen extends StatefulWidget {
  final FocusDatabase db;

  const AcademicsScreen({super.key, required this.db});

  @override
  State<AcademicsScreen> createState() => _AcademicsScreenState();
}

class _AcademicsScreenState extends State<AcademicsScreen> {
  List<Subject> _subjects = [];
  List<Assignment> _assignments = [];
  List<Exam> _exams = [];
  List<Exam> _conflictingExams = [];

  @override
  void initState() {
    super.initState();
    _loadAcademicData();
  }

  Future<void> _loadAcademicData() async {
    var subjects = await widget.db.academicRepo.getAllSubjects();
    if (subjects.isEmpty) {
      // Seed default subject
      final sub = Subject(name: 'Computer Science', code: 'CS-301', colorHex: '#00D2FF', teacherName: 'Prof. Turing');
      await widget.db.academicRepo.insertSubject(sub);
      subjects = await widget.db.academicRepo.getAllSubjects();
    }

    final assignments = await widget.db.academicRepo.getAllAssignments();
    final exams = await widget.db.academicRepo.getAllExams();

    // Check for collisions across exams
    final collisions = <Exam>[];
    for (final exam in exams) {
      final matches = await widget.db.academicRepo.detectExamConflicts(exam.examDate, excludeExamId: exam.id);
      if (matches.isNotEmpty && !collisions.any((e) => e.id == exam.id)) {
        collisions.add(exam);
      }
    }

    if (mounted) {
      setState(() {
        _subjects = subjects;
        _assignments = assignments;
        _exams = exams;
        _conflictingExams = collisions;
      });
    }
  }

  void _showAddSubjectDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final teacherCtrl = TextEditingController();

    FocusBottomSheet.show(
      context: context,
      title: 'New Subject',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.lg, vertical: FocusSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FocusTextField(label: 'Subject Name', hint: 'e.g. Linear Algebra', controller: nameCtrl, autofocus: true),
            const SizedBox(height: FocusSpacing.sm),
            FocusTextField(label: 'Course Code', hint: 'e.g. MATH-204', controller: codeCtrl),
            const SizedBox(height: FocusSpacing.sm),
            FocusTextField(label: 'Instructor / Teacher', hint: 'e.g. Dr. Gauss', controller: teacherCtrl),
            const SizedBox(height: FocusSpacing.lg),
            FocusButton(
              label: 'Add Subject',
              isFullWidth: true,
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final sub = Subject(
                  name: nameCtrl.text.trim(),
                  code: codeCtrl.text.trim(),
                  teacherName: teacherCtrl.text.trim(),
                );
                await widget.db.academicRepo.insertSubject(sub);
                Navigator.of(context).pop();
                _loadAcademicData();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExamDialog() {
    if (_subjects.isEmpty) return;
    final titleCtrl = TextEditingController();
    final venueCtrl = TextEditingController();
    var selectedSubjectId = _subjects.first.id;
    var examDate = DateTime.now().add(const Duration(days: 7));

    FocusBottomSheet.show(
      context: context,
      title: 'Schedule Exam',
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.lg, vertical: FocusSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FocusTextField(label: 'Exam Title', hint: 'e.g. Midterm Examination', controller: titleCtrl, autofocus: true),
                const SizedBox(height: FocusSpacing.sm),
                DropdownButtonFormField<String>(
                  value: selectedSubjectId,
                  dropdownColor: FocusColors.darkSurfaceHigh,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    filled: true,
                    fillColor: FocusColors.darkSurfaceHigh,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(FocusSpacing.radiusMd)),
                  ),
                  items: _subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (val) {
                    if (val != null) setSheetState(() => selectedSubjectId = val);
                  },
                ),
                const SizedBox(height: FocusSpacing.sm),
                FocusTextField(label: 'Exam Hall / Venue', hint: 'e.g. Hall B, Room 204', controller: venueCtrl),
                const SizedBox(height: FocusSpacing.md),
                Row(
                  children: [
                    Text('Date: ${FocusTimeUtils.formatReadableDate(examDate)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    FocusButton(
                      label: 'Pick Date',
                      height: 32,
                      variant: FocusButtonVariant.secondary,
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: examDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setSheetState(() => examDate = picked);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: FocusSpacing.lg),
                FocusButton(
                  label: 'Save Exam',
                  isFullWidth: true,
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final exam = Exam(
                      subjectId: selectedSubjectId,
                      title: titleCtrl.text.trim(),
                      examDate: examDate,
                      venue: venueCtrl.text.trim(),
                    );
                    await widget.db.academicRepo.insertExam(exam);
                    Navigator.of(ctx).pop();
                    _loadAcademicData();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.school),
        label: const Text('Add Exam'),
        backgroundColor: FocusColors.electricBlue,
        onPressed: _showAddExamDialog,
      ),
      body: ListView(
        padding: FocusSpacing.insetAllLg,
        children: [
          // Conflict Detection Banner
          if (_conflictingExams.isNotEmpty) ...[
            Container(
              padding: FocusSpacing.insetAllMd,
              decoration: BoxDecoration(
                color: FocusColors.coralDanger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
                border: Border.all(color: FocusColors.coralDanger.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: FocusColors.coralDanger, size: 24),
                  const SizedBox(width: FocusSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deadline Collision Detected',
                          style: TextStyle(fontWeight: FontWeight.w700, color: FocusColors.coralDanger, fontSize: 13),
                        ),
                        Text(
                          '${_conflictingExams.length} exams are scheduled within the same day. Consider planning revision blocks early.',
                          style: const TextStyle(fontSize: 12, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FocusSpacing.md),
          ],

          // Subjects Section
          FocusSectionHeader(
            title: 'ENROLLED SUBJECTS',
            actionLabel: '+ Subject',
            onAction: _showAddSubjectDialog,
          ),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                final sub = _subjects[index];
                return Padding(
                  padding: const EdgeInsets.only(right: FocusSpacing.sm),
                  child: FocusCard(
                    padding: FocusSpacing.insetAllMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(sub.code.isEmpty ? 'SUBJ' : sub.code, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: FocusColors.electricBlue)),
                        Text(sub.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        if (sub.teacherName.isNotEmpty)
                          Text(sub.teacherName, style: const TextStyle(fontSize: 11, color: FocusColors.darkTextMuted)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: FocusSpacing.lg),

          // Exams Section
          const FocusSectionHeader(title: 'UPCOMING EXAMS & TIMETABLES'),
          if (_exams.isEmpty)
            const FocusCard(
              padding: FocusSpacing.insetAllMd,
              child: Text('No upcoming exams scheduled. Tap "Add Exam" to add one.', style: TextStyle(fontSize: 13, color: FocusColors.darkTextMuted)),
            )
          else
            ..._exams.map((exam) {
              final daysLeft = exam.examDate.difference(DateTime.now()).inDays;
              return Padding(
                padding: const EdgeInsets.only(bottom: FocusSpacing.sm),
                child: FocusCard(
                  padding: FocusSpacing.insetAllMd,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: FocusColors.electricBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(FocusSpacing.radiusSm),
                        ),
                        child: const Icon(Icons.event_note, color: FocusColors.electricBlue, size: 20),
                      ),
                      const SizedBox(width: FocusSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exam.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text(
                              '${FocusTimeUtils.formatReadableDate(exam.examDate)} • ${exam.durationMinutes} min • Venue: ${exam.venue.isEmpty ? "TBD" : exam.venue}',
                              style: const TextStyle(fontSize: 11, color: FocusColors.darkTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: daysLeft <= 3 ? FocusColors.coralDanger.withOpacity(0.2) : FocusColors.emeraldGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(FocusSpacing.radiusPill),
                        ),
                        child: Text(
                          daysLeft <= 0 ? 'TODAY' : '$daysLeft days left',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: daysLeft <= 3 ? FocusColors.coralDanger : FocusColors.emeraldGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
