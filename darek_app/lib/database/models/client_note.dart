class ClientNote {
  final int? id;
  final int clientId;
  final String content;
  final DateTime createdAt;
  final int userId;
  final NoteType type;
  final NoteImportance importance;
  final List<String> tags;

  ClientNote({
    this.id,
    required this.clientId,
    required this.content,
    required this.createdAt,
    required this.userId,
    this.type = NoteType.general,
    this.importance = NoteImportance.normal,
    this.tags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'type': type.toString(),
      'importance': importance.toString(),
      'tags': tags.join(','),
    };
  }

  static ClientNote fromMap(Map<String, dynamic> map) {
    return ClientNote(
      id: map['id'],
      clientId: map['clientId'],
      content: map['content'],
      createdAt: DateTime.parse(map['createdAt']),
      userId: map['userId'],
      type: NoteType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => NoteType.general,
      ),
      importance: NoteImportance.values.firstWhere(
        (e) => e.toString() == map['importance'],
        orElse: () => NoteImportance.normal,
      ),
      tags: map['tags']?.split(',') ?? [],
    );
  }
}

enum NoteType {
  general,      // Ogólne notatki
  order,        // Zamówienia
  price,        // Informacje o cenach
  meeting,      // Notatki ze spotkań
  contact,      // Dane kontaktowe
  feedback,     // Opinie i uwagi
  preorder,     // Informacje o preorderach
  complaint     // Reklamacje
}

enum NoteImportance {
  low,
  normal,
  high,
  urgent
}