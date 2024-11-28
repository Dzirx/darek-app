import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../database/models/client.dart';
import '../../database/models/client_note.dart';
import '../../utils/note_utils.dart';

Future<void> showAddNoteDialog(
  BuildContext context,
  Client client,
  int userId,
  DatabaseHelper dbHelper,
) async {
  NoteType selectedType = NoteType.general;
  NoteImportance selectedImportance = NoteImportance.normal;
  final contentController = TextEditingController();
  final tagsController = TextEditingController();

  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Nowa notatka'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(
              builder: (context, setState) => DropdownButtonFormField<NoteType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Typ notatki'),
                items: NoteType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(getNoteTypeName(type)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedType = value!),
              ),
            ),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setState) => DropdownButtonFormField<NoteImportance>(
                value: selectedImportance,
                decoration: const InputDecoration(labelText: 'Ważność'),
                items: NoteImportance.values.map((importance) {
                  return DropdownMenuItem(
                    value: importance,
                    child: Text(getImportanceName(importance)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedImportance = value!),
              ),
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
            final note = ClientNote(
              clientId: client.id!,
              content: contentController.text,
              createdAt: DateTime.now(),
              userId: userId,
              type: selectedType,
              importance: selectedImportance,
              tags: tagsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList(),
            );

            await dbHelper.createNote(note);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Dodaj'),
        ),
      ],
    ),
  );
}