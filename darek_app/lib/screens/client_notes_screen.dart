import 'package:flutter/material.dart';
import '../widgets/client_notes/client_list_view.dart';
import '../widgets/client_notes/client_notes_view.dart';
import '../widgets/client_notes/add_client_dialog.dart';
import '../widgets/client_notes/add_note_dialog.dart';
import '../database/database_helper.dart';
import '../database/models/client.dart';

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

  

  void _selectClient(Client client) {
    setState(() {
      _selectedClient = client;
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
        _buildSearchBar(),
        Expanded(
          child: _selectedClient == null
            ? ClientListView(
                clients: _clients,
                onClientSelected: _selectClient,
              )
            : ClientNotesView(
                client: _selectedClient!,
                userId: widget.userId,
                onBack: () => setState(() => _selectedClient = null),
              ),
        ),
      ],
      ),
      floatingActionButton: _selectedClient != null
          ? FloatingActionButton(
              onPressed: () => showAddNoteDialog(
                context,
                _selectedClient!,
                widget.userId,
                _dbHelper,
              ),
              child: const Icon(Icons.add),
            )
          : FloatingActionButton(
              onPressed: () => showAddClientDialog(
                context,
                widget.userId,
                _dbHelper,
                onClientAdded: _loadClients,
              ),
              child: const Icon(Icons.person_add),
            ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
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
        ],
      ),
    );
  }
}