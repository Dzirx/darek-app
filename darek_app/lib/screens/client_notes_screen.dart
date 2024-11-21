// lib/screens/client_notes_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../database/models/client.dart';
import '../database/models/client_note.dart';
import '../services/voice_command_service.dart';

class ClientNotesScreen extends StatefulWidget {
  final int userId;

  const ClientNotesScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ClientNotesScreen> createState() => _ClientNotesScreenState();
}

class _ClientNotesScreenState extends State<ClientNotesScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();
  bool _isRecording = false;
  List<Client> _clients = [];
  Client? _selectedClient;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    final clients = await _dbHelper.getRecentClients(widget.userId);
    setState(() {
      _clients = clients;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notatki Klientów'),
      ),
      body: Column(
        children: [
          // Wyszukiwarka klientów
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Szukaj klienta...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _searchClients,
                  ),
                ),
                IconButton(
                  icon: Icon(_isRecording ? Icons.mic_off : Icons.mic),
                  color: _isRecording ? Colors.red : null,
                  onPressed: _toggleVoiceSearch,
                ),
              ],
            ),
          ),

          // Lista klientów
          if (_selectedClient == null)
            Expanded(
              child: ListView.builder(
                itemCount: _clients.length,
                itemBuilder: (context, index) {
                  final client = _clients[index];
                  return ListTile(
                    title: Text(client.name),
                    subtitle: Text(client.company ?? ''),
                    leading: _getClientCategoryIcon(client.category),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _selectClient(client),
                  );
                },
              ),
            ),

          // Notatki wybranego klienta
          if (_selectedClient != null)
            Expanded(
              child: _ClientNotesView(
                client: _selectedClient!,
                userId: widget.userId,
                onBack: () {
                  setState(() {
                    _selectedClient = null;
                  });
                },
              ),
            ),
        ],
      ),
      floatingActionButton: _selectedClient != null
          ? FloatingActionButton(
              onPressed: () => _showAddNoteDialog(context),
              child: const Icon(Icons.add),
            )
          : FloatingActionButton(
              onPressed: () => _showAddClientDialog(context),
              child: const Icon(Icons.person_add),
            ),
    );
  }

  Widget _getClientCategoryIcon(ClientCategory category) {
    switch (category) {
      case ClientCategory.vip:
        return const Icon(Icons.star, color: Colors.amber);
      case ClientCategory.standard:
        return const Icon(Icons.person, color: Colors.blue);
      case ClientCategory.inactive:
        return const Icon(Icons.person_outline, color: Colors.grey);
    }
  }

  Future<void> _searchClients(String query) async {
    if (query.isEmpty) {
      await _loadClients();
    } else {
      final results = await _dbHelper.searchClients(query, widget.userId);
      setState(() {
        _clients = results;
      });
    }
  }

  void _toggleVoiceSearch() {
    // TODO: Implement voice search
  }

  void _selectClient(Client client) {
    setState(() {
      _selectedClient = client;
    });
  }

  Future<void> _showAddNoteDialog(BuildContext context) async {
    final typeController = TextEditingController();
    final contentController = TextEditingController();
    final tagsController = TextEditingController();
    NoteType selectedType = NoteType.general;
    NoteImportance selectedImportance = NoteImportance.normal;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nowa notatka'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<NoteType>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Typ notatki',
                ),
                items: NoteType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getNoteTypeName(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<NoteImportance>(
                value: selectedImportance,
                decoration: const InputDecoration(
                  labelText: 'Ważność',
                ),
                items: NoteImportance.values.map((importance) {
                  return DropdownMenuItem(
                    value: importance,
                    child: Text(_getImportanceName(importance)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedImportance = value!;
                  });
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Treść notatki',
                ),
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
                clientId: _selectedClient!.id!,
                content: contentController.text,
                createdAt: DateTime.now(),
                userId: widget.userId,
                type: selectedType,
                importance: selectedImportance,
                tags: tagsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
              );

              await _dbHelper.createNote(note);
              if (!context.mounted) return;
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );
  }

  String _getNoteTypeName(NoteType type) {
    switch (type) {
      case NoteType.general:
        return 'Ogólna';
      case NoteType.order:
        return 'Zamówienie';
      case NoteType.price:
        return 'Cennik';
      case NoteType.meeting:
        return 'Spotkanie';
      case NoteType.contact:
        return 'Kontakt';
      case NoteType.feedback:
        return 'Opinia';
      case NoteType.preorder:
        return 'Preorder';
      case NoteType.complaint:
        return 'Reklamacja';
    }
  }

  String _getImportanceName(NoteImportance importance) {
    switch (importance) {
      case NoteImportance.low:
        return 'Niska';
      case NoteImportance.normal:
        return 'Normalna';
      case NoteImportance.high:
        return 'Wysoka';
      case NoteImportance.urgent:
        return 'Pilne';
    }
  }

  Future<void> _showAddClientDialog(BuildContext context) async {
    // TODO: Implement add client dialog
  }
}

class _ClientNotesView extends StatelessWidget {
  final Client client;
  final int userId;
  final VoidCallback onBack;

  const _ClientNotesView({
    required this.client,
    required this.userId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Nagłówek z informacjami o kliencie
        Card(
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
                      onPressed: onBack,
                    ),
                    Expanded(
                      child: Text(
                        client.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                if (client.company != null)
                  Text(
                    client.company!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                if (client.phoneNumber != null)
                  Text(
                    'Tel: ${client.phoneNumber}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
        ),

        // Lista notatek
        Expanded(
          child: FutureBuilder<List<ClientNote>>(
            future: DatabaseHelper.instance.getNotesForClient(client.id!),
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
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      title: Text(note.content),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('dd.MM.yyyy HH:mm').format(note.createdAt),
                          ),
                          if (note.tags.isNotEmpty)
                            Wrap(
                              spacing: 4,
                              children: note.tags.map((tag) {
                                return Chip(
                                  label: Text(tag),
                                  visualDensity: VisualDensity.compact,
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                      leading: _getNoteTypeIcon(note.type),
                      trailing: _getImportanceIcon(note.importance),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _getNoteTypeIcon(NoteType type) {
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

  Widget _getImportanceIcon(NoteImportance importance) {
    IconData iconData;
    Color color;

    switch (importance) {
      case NoteImportance.low:
        return const SizedBox.shrink(); // Brak ikony dla niskiej ważności
      case NoteImportance.normal:
        return const SizedBox.shrink(); // Brak ikony dla normalnej ważności
      case NoteImportance.high:
        iconData = Icons.priority_high;
        color = Colors.orange;
        break;
      case NoteImportance.urgent:
        iconData = Icons.warning;
        color = Colors.red;
        break;
    }

    return Icon(iconData, color: color);
  }
}