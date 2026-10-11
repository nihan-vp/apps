import 'dart:async';
import 'package:flutter/material.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';

class FocusSessionScreen extends StatefulWidget {
  final FocusDatabase db;
  final String? initialIntention;
  final int? initialDurationMinutes;
  final String? initialTaskId;

  const FocusSessionScreen({
    super.key,
    required this.db,
    this.initialIntention,
    this.initialDurationMinutes,
    this.initialTaskId,
  });

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> {
  final MonotonicClock _clock = MonotonicClock();
  Timer? _ticker;

  int _targetMinutes = 25;
  String _intention = '';
  String? _linkedTaskId;
  SessionState _sessionState = SessionState.idle;
  String _soundAmbience = 'none';
  final TextEditingController _intentionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _targetMinutes = widget.initialDurationMinutes ?? 25;
    _intention = widget.initialIntention ?? '';
    _linkedTaskId = widget.initialTaskId;
    _intentionCtrl.text = _intention;
    _checkActiveSession();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _intentionCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkActiveSession() async {
    final active = await widget.db.controlRepo.getActiveFocusSession();
    if (active != null) {
      setState(() {
        _targetMinutes = active.targetDurationMinutes;
        _intention = active.intention;
        _intentionCtrl.text = active.intention;
        _linkedTaskId = active.linkedTaskId;
        _sessionState = active.state;
        _soundAmbience = active.soundAmbience;
      });
      if (active.state == SessionState.running) {
        _clock.start();
        _startTicker();
      }
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
      if (_clock.elapsed.inSeconds >= (_targetMinutes * 60)) {
        _onFinish();
      }
    });
  }

  Future<void> _onStart() async {
    setState(() {
      _intention = _intentionCtrl.text.trim();
      _sessionState = SessionState.running;
    });
    _clock.reset();
    _clock.start();
    _startTicker();

    final session = FocusSession(
      title: 'Focus Session',
      intention: _intention.isEmpty ? 'Deep Focus' : _intention,
      targetDurationMinutes: _targetMinutes,
      state: SessionState.running,
      linkedTaskId: _linkedTaskId,
      soundAmbience: _soundAmbience,
      startedAt: DateTime.now(),
    );
    await widget.db.controlRepo.insertFocusSession(session);
  }

  Future<void> _onPause() async {
    _clock.pause();
    setState(() => _sessionState = SessionState.paused);
  }

  Future<void> _onResume() async {
    _clock.resume();
    setState(() => _sessionState = SessionState.running);
  }

  Future<void> _onCancel() async {
    _clock.reset();
    _ticker?.cancel();
    setState(() => _sessionState = SessionState.idle);

    final active = await widget.db.controlRepo.getActiveFocusSession();
    if (active != null) {
      await widget.db.controlRepo.updateFocusSession(
        active.copyWith(state: SessionState.cancelled),
      );
    }
  }

  Future<void> _onFinish() async {
    _clock.pause();
    _ticker?.cancel();
    final elapsedSec = _clock.elapsed.inSeconds;

    final active = await widget.db.controlRepo.getActiveFocusSession();
    if (active != null) {
      await widget.db.controlRepo.updateFocusSession(
        active.copyWith(
          state: SessionState.completed,
          actualDurationSeconds: elapsedSec,
          completedAt: DateTime.now(),
        ),
      );
    }

    setState(() => _sessionState = SessionState.idle);
    _clock.reset();

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('🎉 Session Complete!'),
          content: Text(
            'Outstanding work! You focused for ${(elapsedSec / 60).toStringAsFixed(1)} minutes.\n\n'
            'Intention: ${_intention.isEmpty ? "Deep Focus" : _intention}',
          ),
          actions: [
            FocusButton(
              label: 'Done',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final elapsedSeconds = _clock.elapsed.inSeconds;
    final totalSeconds = _targetMinutes * 60;

    return Scaffold(
      body: SingleChildScrollView(
        padding: FocusSpacing.insetAllLg,
        child: Column(
          children: [
            const SizedBox(height: FocusSpacing.md),

            // Timer display & controls
            FocusTimerWidget(
              totalSeconds: totalSeconds,
              elapsedSeconds: elapsedSeconds,
              state: _sessionState,
              intention: _intention,
              onStart: _onStart,
              onPause: _onPause,
              onResume: _onResume,
              onCancel: _onCancel,
              onFinish: _onFinish,
            ),
            const SizedBox(height: FocusSpacing.xl),

            // Session Configuration (when idle)
            if (_sessionState == SessionState.idle) ...[
              // Intention Input
              FocusCard(
                padding: FocusSpacing.insetAllMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Session Intention', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: FocusSpacing.xs),
                    FocusTextField(
                      hint: 'What specific outcome are you working toward?',
                      controller: _intentionCtrl,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FocusSpacing.md),

              // Duration Presets
              FocusCard(
                padding: FocusSpacing.insetAllMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Duration: $_targetMinutes minutes', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: FocusSpacing.xs),
                    Wrap(
                      spacing: FocusSpacing.sm,
                      children: [
                        ChoiceChip(label: const Text('25m Pomodoro'), selected: _targetMinutes == 25, onSelected: (_) => setState(() => _targetMinutes = 25)),
                        ChoiceChip(label: const Text('45m Deep Study'), selected: _targetMinutes == 45, onSelected: (_) => setState(() => _targetMinutes = 45)),
                        ChoiceChip(label: const Text('50m Sprint'), selected: _targetMinutes == 50, onSelected: (_) => setState(() => _targetMinutes = 50)),
                        ChoiceChip(label: const Text('5m Short Break'), selected: _targetMinutes == 5, onSelected: (_) => setState(() => _targetMinutes = 5)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FocusSpacing.md),

              // Sound Ambience
              FocusCard(
                padding: FocusSpacing.insetAllMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sound Ambience', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: FocusSpacing.xs),
                    Wrap(
                      spacing: FocusSpacing.sm,
                      children: [
                        ChoiceChip(label: const Text('Off'), selected: _soundAmbience == 'none', onSelected: (_) => setState(() => _soundAmbience = 'none')),
                        ChoiceChip(label: const Text('White Noise'), selected: _soundAmbience == 'white_noise', onSelected: (_) => setState(() => _soundAmbience = 'white_noise')),
                        ChoiceChip(label: const Text('Rain'), selected: _soundAmbience == 'rain', onSelected: (_) => setState(() => _soundAmbience = 'rain')),
                        ChoiceChip(label: const Text('Forest'), selected: _soundAmbience == 'forest', onSelected: (_) => setState(() => _soundAmbience = 'forest')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
