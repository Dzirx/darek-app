import 'package:flutter/material.dart';
import '../../database/models/client_note.dart';

class NoteImportanceIcon extends StatelessWidget {
  final NoteImportance importance;

  const NoteImportanceIcon({
    Key? key,
    required this.importance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (importance) {
      case NoteImportance.low:
      case NoteImportance.normal:
        return const SizedBox.shrink();
      case NoteImportance.high:
        return const Icon(Icons.priority_high, color: Colors.orange);
      case NoteImportance.urgent:
        return const Icon(Icons.warning, color: Colors.red);
    }
  }
}