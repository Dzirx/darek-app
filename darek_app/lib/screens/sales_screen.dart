import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../database/models/sale.dart';
import '../database/models/client.dart';

class SalesScreen extends StatefulWidget {
  final int userId;

  const SalesScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  DateTime? _startDate;
  DateTime? _endDate;
  final _searchController = TextEditingController();
  List<Sale> _sales = [];
  double _totalAmount = 0;

  @override
  void initState() {
    super.initState();
    // Domyślnie pokazujemy sprzedaż z ostatnich 30 dni
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
    _loadSales();
  }

  Future<void> _loadSales() async {
    final sales = await _dbHelper.getSalesForUser(
      widget.userId,
      startDate: _startDate,
      endDate: _endDate,
    );

    final total = await _dbHelper.getTotalSalesForPeriod(
      widget.userId,
      _startDate!,
      _endDate!,
    );

    setState(() {
      _sales = sales;
      _totalAmount = total;
    });
  }

  Future<void> _selectDateRange() async {
    final pickedDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate!,
        end: _endDate!,
      ),
    );

    if (pickedDateRange != null) {
      setState(() {
        _startDate = pickedDateRange.start;
        _endDate = pickedDateRange.end;
      });
      _loadSales();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sprzedaż'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSaleDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Panel podsumowania
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Okres: ${DateFormat('dd.MM.yyyy').format(_startDate!)} - ${DateFormat('dd.MM.yyyy').format(_endDate!)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Suma sprzedaży: ${_totalAmount.toStringAsFixed(2)} zł',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),

          // Pole wyszukiwania
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Szukaj klienta...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // TODO: Implementacja wyszukiwania
              },
            ),
          ),

          // Lista sprzedaży
          Expanded(
            child: ListView.builder(
              itemCount: _sales.length,
              itemBuilder: (context, index) {
                final sale = _sales[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    title: Text(sale.clientName),
                    subtitle: Text(
                      '${DateFormat('dd.MM.yyyy HH:mm').format(sale.dateTime)}\n${sale.description ?? ''}',
                    ),
                    trailing: Text(
                      '${sale.amount.toStringAsFixed(2)} zł',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () => _showSaleDetails(context, sale),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSaleDialog(BuildContext context) async {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  Client? selectedClient;
  List<Client> clients = await _dbHelper.getRecentClients(widget.userId, limit: 100);

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Dodaj sprzedaż'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Client>(
              items: clients.map((client) {
                return DropdownMenuItem(
                  value: client,
                  child: Text(client.name),
                );
              }).toList(),
              onChanged: (value) {
                selectedClient = value;
              },
              decoration: const InputDecoration(
                labelText: 'Klient',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Kwota (zł)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Opis',
              ),
              maxLines: 3,
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
            if (selectedClient == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wybierz klienta')),
              );
              return;
            }
            try {
              final amount = double.parse(amountController.text);
              final sale = Sale(
                amount: amount,
                clientName: selectedClient!.name,
                dateTime: DateTime.now(),
                description: descriptionController.text,
                userId: widget.userId,
              );

              await _dbHelper.createSale(sale);
              if (!context.mounted) return;
              Navigator.of(context).pop();
              _loadSales();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Błąd: $e')),
              );
            }
          },
          child: const Text('Dodaj'),
        ),
      ],
    ),
  );
}

Future<void> _editSale(Sale sale) async {
  final amountController = TextEditingController(text: sale.amount.toString());
  final descriptionController = TextEditingController(text: sale.description);
  List<Client> clients = await _dbHelper.getRecentClients(widget.userId, limit: 100);
  
  // Znajdź aktualnego klienta
  Client selectedClient = clients.firstWhere(
    (client) => client.name == sale.clientName,
    orElse: () => clients.first,
  );

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edytuj sprzedaż'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(
              builder: (context, setState) => DropdownButtonFormField<String>(
                value: selectedClient.name,
                items: clients.map((client) => 
                  DropdownMenuItem(
                    value: client.name,
                    child: Text(client.name),
                  )
                ).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedClient = clients.firstWhere((c) => c.name == value);
                  }
                },
                decoration: const InputDecoration(labelText: 'Klient'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Kwota (zł)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Opis'),
              maxLines: 3,
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
            try {
              final updatedSale = Sale(
                id: sale.id,
                amount: double.parse(amountController.text),
                clientName: selectedClient.name,
                dateTime: sale.dateTime,
                description: descriptionController.text,
                userId: widget.userId,
              );
              await _dbHelper.updateSale(updatedSale);
              if (!context.mounted) return;
              Navigator.of(context).pop();
              _loadSales();
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Błąd: $e'))
              );
            }
          },
          child: const Text('Zapisz'),
        ),
      ],
    ),
  );
}

Future<void> _deleteSale(Sale sale) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Usuń sprzedaż'),
      content: const Text('Czy na pewno chcesz usunąć tę sprzedaż?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Anuluj')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Usuń'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await _dbHelper.deleteSale(sale.id!);
    _loadSales();
  }
}

  void _showSaleDetails(BuildContext context, Sale sale) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Szczegóły sprzedaży'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Klient: ${sale.clientName}'),
          Text('Kwota: ${sale.amount.toStringAsFixed(2)} zł'),
          Text('Data: ${DateFormat('dd.MM.yyyy HH:mm').format(sale.dateTime)}'),
          if (sale.description != null) Text('Opis: ${sale.description}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _editSale(sale);
          },
          child: const Text('Edytuj'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _deleteSale(sale);
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Usuń'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Zamknij'),
        ),
      ],
    ),
  );
}
}