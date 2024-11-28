import '../../database/models/client_note.dart';
import '../../database/models/client.dart';

String getNoteTypeName(NoteType type) {
  return switch (type) {
    NoteType.general => 'Ogólna',
    NoteType.order => 'Zamówienie',
    NoteType.price => 'Cennik', 
    NoteType.meeting => 'Spotkanie',
    NoteType.contact => 'Kontakt',
    NoteType.feedback => 'Opinia',
    NoteType.preorder => 'Preorder',
    NoteType.complaint => 'Reklamacja'
  };
}

String getImportanceName(NoteImportance importance) {
  return switch (importance) {
    NoteImportance.low => 'Niska',
    NoteImportance.normal => 'Normalna',
    NoteImportance.high => 'Wysoka',
    NoteImportance.urgent => 'Pilne'
  };
}

String getClientCategoryName(ClientCategory category) {
  return switch (category) {
    ClientCategory.vip => 'VIP',
    ClientCategory.standard => 'Standardowy',
    ClientCategory.inactive => 'Nieaktywny'
  };
}