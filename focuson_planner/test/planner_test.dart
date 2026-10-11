import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_planner/main.dart';
import 'package:focuson_planner/screens/planner_home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  late FocusDatabase db;

  setUp(() async {
    db = await FocusDatabase.openInMemory();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('FocusON Planner boots and displays tasks screen', (tester) async {
    await tester.pumpWidget(FocusPlannerApp(db: db));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(PlannerHomeScreen), findsOneWidget);
    expect(find.text('Tasks'), findsWidgets);
  });

  test('Planner task persistence and reminder cancellation on completion', () async {
    final task = Task(
      title: 'Study Operating Systems',
      priority: FocusPriority.urgent,
      dueDate: DateTime.now().add(const Duration(days: 3)),
    );
    await db.taskRepo.insertTask(task);

    final reminder = Reminder(
      targetId: task.id,
      title: 'Reminder for Operating Systems',
      triggerTime: DateTime.now().add(const Duration(days: 1)),
    );
    await db.reminderRepo.insertReminder(reminder);

    // Complete task
    await db.taskRepo.toggleTaskCompletion(task.id);

    final completed = await db.taskRepo.getTaskById(task.id);
    expect(completed?.isCompleted, isTrue);

    final rem = await db.reminderRepo.getReminderById(reminder.id);
    expect(rem?.isCancelled, isTrue);
  });

  test('Exam conflict detection identifies same-day exams', () async {
    final subject = Subject(name: 'Mathematics', code: 'MATH-101');
    await db.academicRepo.insertSubject(subject);

    final date = DateTime(2026, 11, 25, 9, 0);
    final e1 = Exam(subjectId: subject.id, title: 'Calculus Midterm', examDate: date);
    final e2 = Exam(subjectId: subject.id, title: 'Linear Algebra Quiz', examDate: date.add(const Duration(hours: 3)));

    await db.academicRepo.insertExam(e1);
    await db.academicRepo.insertExam(e2);

    final conflicts = await db.academicRepo.detectExamConflicts(date);
    expect(conflicts.length, 2);
  });
}
