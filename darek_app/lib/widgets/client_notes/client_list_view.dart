import 'package:flutter/material.dart';
import '../../database/models/client.dart';
import 'client_category_icon.dart';

class ClientListView extends StatelessWidget {
  final List<Client> clients;
  final Function(Client) onClientSelected;

  const ClientListView({
    Key? key,
    required this.clients,
    required this.onClientSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: clients.length,
        itemBuilder: (context, index) {
          final client = clients[index];
          return ListTile(
            title: Text(client.name),
            subtitle: Text(client.company ?? ''),
            leading: ClientCategoryIcon(category: client.category),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => onClientSelected(client),
          );
        },
      ),
    );
  }
}