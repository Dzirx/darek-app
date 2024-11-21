// lib/models/sale.dart
class Sale {
  final int? id;
  final double amount;
  final String clientName;
  final DateTime dateTime;
  final String? description;
  final int userId;

  Sale({
    this.id,
    required this.amount,
    required this.clientName,
    required this.dateTime,
    this.description,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'clientName': clientName,
      'dateTime': dateTime.toIso8601String(),
      'description': description,
      'userId': userId,
    };
  }

  static Sale fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      amount: map['amount'],
      clientName: map['clientName'],
      dateTime: DateTime.parse(map['dateTime']),
      description: map['description'],
      userId: map['userId'],
    );
  }

  // Metoda pomocnicza do obliczania sumy sprzedaży
  static double calculateTotal(List<Sale> sales) {
    return sales.fold(0, (sum, sale) => sum + sale.amount);
  }

  // Metoda pomocnicza do formatowania kwoty
  String get formattedAmount {
    return '${amount.toStringAsFixed(2)} zł';
  }
}