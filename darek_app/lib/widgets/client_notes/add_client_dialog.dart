import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../database/models/client.dart';
import '../../utils/note_utils.dart';

Future<void> showAddClientDialog(
  BuildContext context,
  int userId,
  DatabaseHelper dbHelper, {
  required VoidCallback onClientAdded,
}) async {
  final nameController = TextEditingController();
  final companyController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  ClientCategory selectedCategory = ClientCategory.standard;

  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Dodaj nowego klienta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nazwa/Nazwisko *',
                hintText: 'Wprowadź nazwę klienta',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: companyController,
              decoration: const InputDecoration(
                labelText: 'Firma',
                hintText: 'Wprowadź nazwę firmy',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                hintText: 'Wprowadź numer telefonu',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Wprowadź adres email',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Adres',
                hintText: 'Wprowadź adres',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) => DropdownButtonFormField<ClientCategory>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Kategoria'),
                items: ClientCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(getClientCategoryName(category)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedCategory = value!),
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
            if (nameController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nazwa klienta jest wymagana'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            try {
              final client = Client(
                name: nameController.text,
                company: companyController.text.isEmpty ? null : companyController.text,
                phoneNumber: phoneController.text.isEmpty ? null : phoneController.text,
                email: emailController.text.isEmpty ? null : emailController.text,
                address: addressController.text.isEmpty ? null : addressController.text,
                userId: userId,
                category: selectedCategory,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              await dbHelper.createClient(client);
              if (context.mounted) {
                Navigator.of(context).pop();
                onClientAdded();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Klient został dodany pomyślnie'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Błąd podczas dodawania klienta: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Dodaj'),
        ),
      ],
    ),
  );
}