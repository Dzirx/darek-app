import 'package:flutter/material.dart';
import '../../database/models/client.dart';

class ClientCategoryIcon extends StatelessWidget {
  final ClientCategory category;

  const ClientCategoryIcon({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (category) {
      case ClientCategory.vip:
        return const Icon(Icons.star, color: Colors.amber);
      case ClientCategory.standard:
        return const Icon(Icons.person, color: Colors.blue);
      case ClientCategory.inactive:
        return const Icon(Icons.person_outline, color: Colors.grey);
    }
  }
}
