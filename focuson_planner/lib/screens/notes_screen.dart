import 'package:flutter/material.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';

class NotesScreen extends StatefulWidget {
  final FocusDatabase db;

  const NotesScreen({super.key, required this.db});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> _notes = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    List<Note> notes;
    if (_searchQuery.trim().isNotEmpty) {
      notes = await widget.db.noteRepo.searchNotes(_searchQuery);
    } else {
      notes = await widget.db.noteRepo.getAllNotes();
    }
    if (mounted) setState(() => _notes = notes);
  }

  void _showAddEditNoteSheet([Note? existing]) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final contentCtrl = TextEditingController(text: existing?.content ?? '');
    final tagsCtrl = TextEditingController(text: existing?.tags.join(', ') ?? '');

    FocusBottomSheet.show(
      context: context,
      title: existing == null ? 'New Note' : 'Edit Note',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.lg, vertical: FocusSpacing.md),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FocusTextField(label: 'Note Title', hint: 'e.g. Calculus Derivatives Summary', controller: titleCtrl, autofocus: true),
              const SizedBox(height: FocusSpacing.sm),
              FocusTextField(label: 'Content (Markdown Supported)', hint: 'Write thoughts, formulas, or checklists...', controller: contentCtrl, maxLines: 6),
              const SizedBox(height: FocusSpacing.sm),
              FocusTextField(label: 'Tags (comma separated)', hint: 'math, formulas, exam', controller: tagsCtrl),
              const SizedBox(height: FocusSpacing.lg),
              FocusButton(
                label: existing == null ? 'Save Note' : 'Update Note',
                isFullWidth: true,
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty) return;
                  final tags = tagsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

                  final note = Note(
                    id: existing?.id,
                    title: titleCtrl.text.trim(),
                    content: contentCtrl.text.trim(),
                    tags: tags,
                    isPinned: existing?.isPinned ?? false,
                  );

                  if (existing == null) {
                    await widget.db.noteRepo.insertNote(note);
                  } else {
                    await widget.db.noteRepo.updateNote(note);
                  }

                  Navigator.of(context).pop();
                  _loadNotes();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.note_add),
        label: const Text('Add Note'),
        backgroundColor: FocusColors.electricBlue,
        onPressed: () => _showAddEditNoteSheet(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: FocusSpacing.lg, vertical: FocusSpacing.sm),
            child: FocusSearchBar(
              hint: 'Search notes and tags...',
              onChanged: (q) {
                setState(() => _searchQuery = q);
                _loadNotes();
              },
            ),
          ),
          Expanded(
            child: _notes.isEmpty
                ? const FocusEmptyState(
                    icon: Icons.notes,
                    title: 'No Notes Found',
                    message: 'Capture study summaries, checklists, and references offline.',
                  )
                : ListView.builder(
                    padding: FocusSpacing.insetAllLg,
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: FocusSpacing.sm),
                        child: FocusCard(
                          padding: FocusSpacing.insetAllMd,
                          onTap: () => _showAddEditNoteSheet(note),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (note.isPinned)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 6),
                                      child: Icon(Icons.push_pin, size: 14, color: FocusColors.electricBlue),
                                    ),
                                  Expanded(
                                    child: Text(
                                      note.title,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18),
                                    onPressed: () async {
                                      await widget.db.noteRepo.togglePin(note.id);
                                      _loadNotes();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: FocusColors.coralDanger),
                                    onPressed: () async {
                                      await widget.db.noteRepo.deleteNote(note.id);
                                      _loadNotes();
                                    },
                                  ),
                                ],
                              ),
                              if (note.content.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  note.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, color: FocusColors.darkTextSecondary),
                                ),
                              ],
                              if (note.tags.isNotEmpty) ...[
                                const SizedBox(height: FocusSpacing.xs),
                                Wrap(
                                  spacing: 4,
                                  children: note.tags.map((t) => Text('#$t', style: const TextStyle(fontSize: 11, color: FocusColors.electricBlue))).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
