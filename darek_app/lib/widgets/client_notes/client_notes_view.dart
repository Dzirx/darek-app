import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/models/client.dart';
import '../../database/models/client_note.dart';
import '../../database/database_helper.dart';
import '../../utils/note_utils.dart';
import 'note_type_icon.dart';
import 'note_importance_icon.dart';

class ClientNotesView extends StatefulWidget {
  final Client client;
  final int userId;
  final VoidCallback onBack;

  const ClientNotesView({
    Key? key,
    required this.client,
    required this.userId,
    required this.onBack,
  }) : super(key: key);

  @override
  State<ClientNotesView> createState() => _ClientNotesViewState();
}

class _ClientNotesViewState extends State<ClientNotesView> {
  late Future<List<ClientNote>> _notesFuture;

  @override
  void initState() {
    super.initState();
    _refreshNotes();
  }

  void _refreshNotes() {
    _notesFuture = DatabaseHelper.instance.getNotesForClient(widget.client.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildClientHeader(context),
        Expanded(
          child: _buildNotesList(),
        ),
      ],
    );
  }

  Widget _buildClientHeader(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                ),
                Expanded(
                  child: Text(
                    widget.client.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            if (widget.client.company != null)
              Text(
                widget.client.company!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            if (widget.client.phoneNumber != null)
              Text(
                'Tel: ${widget.client.phoneNumber}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesList() {
    return FutureBuilder<List<ClientNote>>(
      future: _notesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Błąd: ${snapshot.error}'));
        }

        final notes = snapshot.data ?? [];

        if (notes.isEmpty) {
          return const Center(child: Text('Brak notatek'));
        }

        return ListView.builder(
          itemCount: notes.length,
          itemBuilder: (context, index) => _buildNoteCard(notes[index]),
        );
      },
    );
  }

  Widget _buildNoteCard(ClientNote note) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(note.content),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('dd.MM.yyyy HH:mm').format(note.createdAt)),
            // if (note.tags.isNotEmpty)
            //   Wrap(
            //     spacing: 4,
            //     children: note.tags
            //         .map((tag) => Chip(
            //               label: Text(tag),
            //               visualDensity: VisualDensity.compact,
            //             ))
            //         .toList(),
            //   ),
          ],
        ),
        leading: NoteTypeIcon(type: note.type),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NoteImportanceIcon(importance: note.importance),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editNote(context, note),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteNote(context, note),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editNote(BuildContext context, ClientNote note) async {
  final contentController = TextEditingController(text: note.content);
  final tagsController = TextEditingController(text: note.tags.join(','));
  NoteType selectedType = note.type;
  NoteImportance selectedImportance = note.importance;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edytuj notatkę'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<NoteType>(
              value: selectedType,
              decoration: const InputDecoration(labelText: 'Typ notatki'),
              items: NoteType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(getNoteTypeName(type)),
                );
              }).toList(),
              onChanged: (value) => selectedType = value!,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<NoteImportance>(
              value: selectedImportance,
              decoration: const InputDecoration(labelText: 'Ważność'),
              items: NoteImportance.values.map((importance) {
                return DropdownMenuItem(
                  value: importance,
                  child: Text(getImportanceName(importance)),
                );
              }).toList(),
              onChanged: (value) => selectedImportance = value!,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Treść notatki'),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tagsController,
              decoration: const InputDecoration(
                labelText: 'Tagi (oddzielone przecinkami)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        TextButton(
          onPressed: () async {
            final updatedNote = ClientNote(
              id: note.id,
              clientId: note.clientId,
              content: contentController.text,
              createdAt: note.createdAt,
              userId: note.userId,
              type: selectedType,
              importance: selectedImportance,
              tags: tagsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList(),
            );

            await DatabaseHelper.instance.updateNote(updatedNote);
            if (mounted) {
              Navigator.of(context).pop();
              setState(() {
                _refreshNotes();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notatka zaktualizowana')),
              );
            }
          },
          child: const Text('Zapisz'),
        ),
      ],
    ),
  );
}

Future<void> _deleteNote(BuildContext context, ClientNote note) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Usuń notatkę'),
      content: const Text('Czy na pewno chcesz usunąć tę notatkę?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Anuluj'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Usuń'),
        ),
      ],
    ),
  );

  if (confirmed == true && mounted) {
    await DatabaseHelper.instance.deleteNote(note.id!);
    setState(() {
      _refreshNotes();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notatka została usunięta')),
      );
    }
  }
}
}
