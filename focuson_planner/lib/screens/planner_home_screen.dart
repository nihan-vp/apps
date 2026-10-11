import 'package:flutter/material.dart';
import 'package:focuson_database/focuson_database.dart';
import 'tasks_screen.dart';
import 'academics_screen.dart';
import 'calendar_screen.dart';
import 'notes_screen.dart';
import 'habits_flashcards_screen.dart';

class PlannerHomeScreen extends StatefulWidget {
  final FocusDatabase db;
  final String? sharedText;

  const PlannerHomeScreen({super.key, required this.db, this.sharedText});

  @override
  State<PlannerHomeScreen> createState() => _PlannerHomeScreenState();
}

class _PlannerHomeScreenState extends State<PlannerHomeScreen> {
  int _tabIndex = 0;

  Widget _buildBody() {
    switch (_tabIndex) {
      case 0:
        return TasksScreen(db: widget.db, prefillTitle: widget.sharedText);
      case 1:
        return AcademicsScreen(db: widget.db);
      case 2:
        return CalendarScreen(db: widget.db);
      case 3:
        return NotesScreen(db: widget.db);
      case 4:
        return HabitsFlashcardsScreen(db: widget.db);
      default:
        return TasksScreen(db: widget.db);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Tasks', 'Academics', 'Calendar', 'Notes', 'Habits & Cards'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tabIndex]),
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (idx) => setState(() => _tabIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.check_circle_outline), selectedIcon: Icon(Icons.check_circle), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Academics'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.notes_outlined), selectedIcon: Icon(Icons.notes), label: 'Notes'),
          NavigationDestination(icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories), label: 'Habits'),
        ],
      ),
    );
  }
}
