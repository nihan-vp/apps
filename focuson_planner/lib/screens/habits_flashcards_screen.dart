import 'package:flutter/material.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';

class HabitsFlashcardsScreen extends StatefulWidget {
  final FocusDatabase db;

  const HabitsFlashcardsScreen({super.key, required this.db});

  @override
  State<HabitsFlashcardsScreen> createState() => _HabitsFlashcardsScreenState();
}

class _HabitsFlashcardsScreenState extends State<HabitsFlashcardsScreen> {
  int _tab = 0; // 0 = Habits, 1 = Flashcards
  List<Habit> _habits = [];
  Map<String, int> _streaks = {};
  Map<String, HabitCompletion?> _todayCompletions = {};

  List<FlashcardDeck> _decks = [];
  Map<String, int> _dueCardCounts = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Habits
    var habits = await widget.db.habitRepo.getAllHabits();
    if (habits.isEmpty) {
      final h1 = Habit(title: 'Read 20 pages', frequency: 'daily');
      final h2 = Habit(title: 'Workout / Yoga', frequency: 'daily');
      await widget.db.habitRepo.insertHabit(h1);
      await widget.db.habitRepo.insertHabit(h2);
      habits = await widget.db.habitRepo.getAllHabits();
    }

    final streaks = <String, int>{};
    final completions = <String, HabitCompletion?>{};
    final today = DateTime.now();

    for (final h in habits) {
      streaks[h.id] = await widget.db.habitRepo.calculateStreak(h.id);
      completions[h.id] = await widget.db.habitRepo.getCompletionForDate(h.id, today);
    }

    // Flashcards
    var decks = await widget.db.flashcardRepo.getAllDecks();
    if (decks.isEmpty) {
      final deck = FlashcardDeck(title: 'Computer Science Fundamentals');
      await widget.db.flashcardRepo.insertDeck(deck);
      await widget.db.flashcardRepo.insertCard(Flashcard(deckId: deck.id, front: 'What is idempotency?', back: 'An operation that produces the same result if executed multiple times.'));
      await widget.db.flashcardRepo.insertCard(Flashcard(deckId: deck.id, front: 'What is an ACID transaction?', back: 'Atomicity, Consistency, Isolation, Durability guarantee for databases.'));
      decks = await widget.db.flashcardRepo.getAllDecks();
    }

    final dueCounts = <String, int>{};
    for (final d in decks) {
      final dueCards = await widget.db.flashcardRepo.getDueCardsForDeck(d.id);
      dueCounts[d.id] = dueCards.length;
    }

    if (mounted) {
      setState(() {
        _habits = habits;
        _streaks = streaks;
        _todayCompletions = completions;
        _decks = decks;
        _dueCardCounts = dueCounts;
      });
    }
  }

  void _showAddHabitDialog() {
    final titleCtrl = TextEditingController();
    FocusBottomSheet.show(
      context: context,
      title: 'New Habit',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.lg, vertical: FocusSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FocusTextField(label: 'Habit Title', hint: 'e.g. Daily Meditation', controller: titleCtrl, autofocus: true),
            const SizedBox(height: FocusSpacing.lg),
            FocusButton(
              label: 'Add Habit',
              isFullWidth: true,
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                await widget.db.habitRepo.insertHabit(Habit(title: titleCtrl.text.trim()));
                Navigator.of(context).pop();
                _loadData();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSkipDialog(Habit habit) {
    final reasonCtrl = TextEditingController();
    FocusBottomSheet.show(
      context: context,
      title: 'Intentional Rest Day',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.lg, vertical: FocusSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Taking an intentional rest day preserves your streak without guilt or shame. Give yourself grace when recovering or resting.',
              style: TextStyle(fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: FocusSpacing.md),
            FocusTextField(label: 'Reason for Rest', hint: 'e.g. Recovery day, heavy exam week', controller: reasonCtrl, autofocus: true),
            const SizedBox(height: FocusSpacing.lg),
            FocusButton(
              label: 'Confirm Rest Day',
              isFullWidth: true,
              onPressed: () async {
                await widget.db.habitRepo.recordSkip(habit.id, DateTime.now(), reasonCtrl.text.trim());
                Navigator.of(context).pop();
                _loadData();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startDeckReview(FlashcardDeck deck) async {
    final cards = await widget.db.flashcardRepo.getDueCardsForDeck(deck.id);
    if (cards.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All caught up! No due flashcards in this deck right now.')),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => _FlashcardReviewFlow(deck: deck, cards: cards, db: widget.db),
        ),
      ).then((_) => _loadData());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(_tab == 0 ? Icons.add_task : Icons.style),
        label: Text(_tab == 0 ? 'Add Habit' : 'Add Deck'),
        backgroundColor: FocusColors.electricBlue,
        onPressed: () {
          if (_tab == 0) _showAddHabitDialog();
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.lg, vertical: FocusSpacing.sm),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Daily Habits')),
                ButtonSegment(value: 1, label: Text('Revision Flashcards')),
              ],
              selected: {_tab},
              onSelectionChanged: (set) => setState(() => _tab = set.first),
            ),
          ),
          Expanded(
            child: _tab == 0 ? _buildHabitsList() : _buildDecksList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsList() {
    return ListView.builder(
      padding: FocusSpacing.insetAllLg,
      itemCount: _habits.length,
      itemBuilder: (context, index) {
        final habit = _habits[index];
        final streak = _streaks[habit.id] ?? 0;
        final comp = _todayCompletions[habit.id];
        final isDoneToday = comp != null && !comp.isSkipped;
        final isSkippedToday = comp != null && comp.isSkipped;

        return Padding(
          padding: const EdgeInsets.only(bottom: FocusSpacing.sm),
          child: FocusCard(
            padding: FocusSpacing.insetAllMd,
            child: Row(
              children: [
                InkWell(
                  onTap: () async {
                    if (isDoneToday) {
                      await widget.db.habitRepo.removeCompletion(habit.id, DateTime.now());
                    } else {
                      await widget.db.habitRepo.recordCompletion(habit.id, DateTime.now());
                    }
                    _loadData();
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDoneToday ? FocusColors.emeraldGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(FocusSpacing.radiusSm),
                      border: Border.all(
                        color: isDoneToday ? FocusColors.emeraldGreen : FocusColors.darkBorder,
                        width: 2,
                      ),
                    ),
                    child: isDoneToday ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
                  ),
                ),
                const SizedBox(width: FocusSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      if (isSkippedToday)
                        Text('Rest day: ${comp.skipReason}', style: const TextStyle(fontSize: 11, color: FocusColors.amberWarning))
                      else
                        Text('🔥 $streak day streak', style: const TextStyle(fontSize: 11, color: FocusColors.darkTextSecondary)),
                    ],
                  ),
                ),
                if (!isDoneToday && !isSkippedToday)
                  FocusButton(
                    label: 'Rest Day',
                    height: 32,
                    variant: FocusButtonVariant.subtle,
                    onPressed: () => _showSkipDialog(habit),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDecksList() {
    return ListView.builder(
      padding: FocusSpacing.insetAllLg,
      itemCount: _decks.length,
      itemBuilder: (context, index) {
        final deck = _decks[index];
        final due = _dueCardCounts[deck.id] ?? 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: FocusSpacing.sm),
          child: FocusCard(
            padding: FocusSpacing.insetAllMd,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: FocusColors.lavenderPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(FocusSpacing.radiusSm),
                  ),
                  child: const Icon(Icons.style, color: FocusColors.lavenderPurple, size: 20),
                ),
                const SizedBox(width: FocusSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(deck.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('$due cards due for revision (SM-2 Spaced Repetition)', style: const TextStyle(fontSize: 11, color: FocusColors.darkTextMuted)),
                    ],
                  ),
                ),
                FocusButton(
                  label: 'Review',
                  height: 32,
                  variant: due > 0 ? FocusButtonVariant.primary : FocusButtonVariant.secondary,
                  onPressed: () => _startDeckReview(deck),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FlashcardReviewFlow extends StatefulWidget {
  final FlashcardDeck deck;
  final List<Flashcard> cards;
  final FocusDatabase db;

  const _FlashcardReviewFlow({required this.deck, required this.cards, required this.db});

  @override
  State<_FlashcardReviewFlow> createState() => _FlashcardReviewFlowState();
}

class _FlashcardReviewFlowState extends State<_FlashcardReviewFlow> {
  int _currentIndex = 0;
  bool _showAnswer = false;

  void _submitRating(ConfidenceRating rating) async {
    final currentCard = widget.cards[_currentIndex];
    await widget.db.flashcardRepo.recordReview(currentCard.id, rating);

    if (_currentIndex + 1 < widget.cards.length) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
      });
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Revision Complete!'),
            content: const Text('All due cards in this deck have been scheduled with SuperMemo-2 spaced intervals.'),
            actions: [
              FocusButton(
                label: 'Done',
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.cards[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.deck.title} (${_currentIndex + 1}/${widget.cards.length})'),
      ),
      body: Padding(
        padding: FocusSpacing.insetAllLg,
        child: Column(
          children: [
            Expanded(
              child: FocusCard(
                padding: FocusSpacing.insetAllXl,
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _showAnswer ? 'ANSWER' : 'QUESTION / PROMPT',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: FocusColors.electricBlue),
                        ),
                        const SizedBox(height: FocusSpacing.lg),
                        Text(
                          _showAnswer ? card.back : card.front,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: FocusSpacing.lg),
            if (!_showAnswer)
              FocusButton(
                label: 'Show Answer',
                isFullWidth: true,
                onPressed: () => setState(() => _showAnswer = true),
              )
            else ...[
              const Text('Rate your recall confidence:', style: TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary)),
              const SizedBox(height: FocusSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: FocusButton(
                      label: 'Again',
                      variant: FocusButtonVariant.destructive,
                      onPressed: () => _submitRating(ConfidenceRating.again),
                    ),
                  ),
                  const SizedBox(width: FocusSpacing.xs),
                  Expanded(
                    child: FocusButton(
                      label: 'Hard',
                      variant: FocusButtonVariant.secondary,
                      onPressed: () => _submitRating(ConfidenceRating.hard),
                    ),
                  ),
                  const SizedBox(width: FocusSpacing.xs),
                  Expanded(
                    child: FocusButton(
                      label: 'Good',
                      variant: FocusButtonVariant.primary,
                      onPressed: () => _submitRating(ConfidenceRating.good),
                    ),
                  ),
                  const SizedBox(width: FocusSpacing.xs),
                  Expanded(
                    child: FocusButton(
                      label: 'Easy',
                      onPressed: () => _submitRating(ConfidenceRating.easy),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
