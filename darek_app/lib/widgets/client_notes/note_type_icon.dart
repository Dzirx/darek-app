import 'package:flutter/material.dart';
import '../../database/models/client_note.dart';

class NoteTypeIcon extends StatelessWidget {
  final NoteType type;

  const NoteTypeIcon({
    Key? key,
    required this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color color;

    switch (type) {
      case NoteType.general:
        iconData = Icons.note;
        color = Colors.blue;
        break;
      case NoteType.order:
        iconData = Icons.shopping_cart;
        color = Colors.green;
        break;
      case NoteType.price:
        iconData = Icons.attach_money;
        color = Colors.orange;
        break;
      case NoteType.meeting:
        iconData = Icons.event;
        color = Colors.purple;
        break;
      case NoteType.contact:
        iconData = Icons.contact_phone;
        color = Colors.teal;
        break;
      case NoteType.feedback:
        iconData = Icons.feedback;
        color = Colors.brown;
        break;
      case NoteType.preorder:
        iconData = Icons.schedule;
        color = Colors.deepPurple;
        break;
      case NoteType.complaint:
        iconData = Icons.warning;
        color = Colors.red;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(iconData, color: color),
    );
  }
}
