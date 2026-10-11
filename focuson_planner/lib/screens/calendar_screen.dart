import 'package:flutter/material.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';

class CalendarScreen extends StatefulWidget {
  final FocusDatabase db;

  const CalendarScreen({super.key, required this.db});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  List<CalendarEvent> _events = [];
  List<Task> _dayTasks = [];
  List<CalendarEvent> _overlappingEvents = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final start = FocusTimeUtils.startOfDay(_selectedDate);
    final end = FocusTimeUtils.endOfDay(_selectedDate);

    final events = await widget.db.calendarRepo.getEventsInRange(start, end);
    final tasks = await widget.db.taskRepo.getTodayTasks();

    // Check for overlapping events
    final overlaps = <CalendarEvent>[];
    for (final ev in events) {
      final conflict = await widget.db.calendarRepo.detectOverlaps(ev.startTime, ev.endTime, excludeEventId: ev.id);
      if (conflict.isNotEmpty && !overlaps.any((e) => e.id == ev.id)) {
        overlaps.add(ev);
      }
    }

    if (mounted) {
      setState(() {
        _events = events;
        _dayTasks = tasks;
        _overlappingEvents = overlaps;
      });
    }
  }

  void _showAddEventDialog() {
    final titleCtrl = TextEditingController();
    var startTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 10, 0);
    var endTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 11, 30);

    FocusBottomSheet.show(
      context: context,
      title: 'New Time Block',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.lg, vertical: FocusSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FocusTextField(label: 'Event Title', hint: 'e.g. Deep Study Calculus', controller: titleCtrl, autofocus: true),
            const SizedBox(height: FocusSpacing.md),
            Row(
              children: [
                Text('Start: ${FocusTimeUtils.formatTime(startTime)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                FocusButton(
                  label: 'Set Time',
                  height: 32,
                  variant: FocusButtonVariant.secondary,
                  onPressed: () async {
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(startTime));
                    if (time != null) {
                      setState(() {
                        startTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, time.hour, time.minute);
                        endTime = startTime.add(const Duration(hours: 1));
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: FocusSpacing.lg),
            FocusButton(
              label: 'Block Time',
              isFullWidth: true,
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final ev = CalendarEvent(
                  title: titleCtrl.text.trim(),
                  startTime: startTime,
                  endTime: endTime,
                );
                await widget.db.calendarRepo.insertEvent(ev);
                Navigator.of(context).pop();
                _loadEvents();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Time Block'),
        backgroundColor: FocusColors.electricBlue,
        onPressed: _showAddEventDialog,
      ),
      body: ListView(
        padding: FocusSpacing.insetAllLg,
        children: [
          // Date bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
                  _loadEvents();
                },
              ),
              Text(
                FocusTimeUtils.formatReadableDate(_selectedDate),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
                  _loadEvents();
                },
              ),
            ],
          ),
          const SizedBox(height: FocusSpacing.md),

          // Conflict alert banner
          if (_overlappingEvents.isNotEmpty) ...[
            Container(
              padding: FocusSpacing.insetAllMd,
              decoration: BoxDecoration(
                color: FocusColors.amberWarning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
                border: Border.all(color: FocusColors.amberWarning.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: FocusColors.amberWarning, size: 20),
                  SizedBox(width: FocusSpacing.sm),
                  Expanded(
                    child: Text(
                      'Time Conflict: You have overlapping time blocks scheduled for this day.',
                      style: TextStyle(fontSize: 12, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FocusSpacing.md),
          ],

          // Time Blocks List
          const FocusSectionHeader(title: 'TIME BLOCKS'),
          if (_events.isEmpty)
            const FocusCard(
              padding: FocusSpacing.insetAllMd,
              child: Text(
                'No time blocks scheduled for this day. Tap "Add Time Block" to protect dedicated focus time.',
                style: TextStyle(fontSize: 13, color: FocusColors.darkTextMuted),
              ),
            )
          else
            ..._events.map((ev) {
              final timeSpan = '${FocusTimeUtils.formatTime(ev.startTime)} - ${FocusTimeUtils.formatTime(ev.endTime)}';
              return Padding(
                padding: const EdgeInsets.only(bottom: FocusSpacing.sm),
                child: FocusCard(
                  padding: FocusSpacing.insetAllMd,
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 36,
                        decoration: BoxDecoration(
                          color: FocusColors.electricBlue,
                          borderRadius: BorderRadius.circular(FocusSpacing.radiusPill),
                        ),
                      ),
                      const SizedBox(width: FocusSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ev.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text(timeSpan, style: const TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: FocusColors.coralDanger),
                        onPressed: () async {
                          await widget.db.calendarRepo.deleteEvent(ev.id);
                          _loadEvents();
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: FocusSpacing.lg),
          const FocusSectionHeader(title: 'TASKS DUE ON THIS DAY'),
          if (_dayTasks.isEmpty)
            const FocusCard(
              padding: FocusSpacing.insetAllMd,
              child: Text('No deadlines falling on this date.', style: TextStyle(fontSize: 13, color: FocusColors.darkTextMuted)),
            )
          else
            ..._dayTasks.map((t) {
              return Padding(
                padding: const EdgeInsets.only(bottom: FocusSpacing.xs),
                child: FocusCard(
                  padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.md, vertical: FocusSpacing.sm),
                  child: Row(
                    children: [
                      const Icon(Icons.circle_outlined, size: 14, color: FocusColors.emeraldGreen),
                      const SizedBox(width: FocusSpacing.sm),
                      Expanded(child: Text(t.title, style: const TextStyle(fontSize: 13))),
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
