import '../../database/database_helper.dart';
import '../../database/models/client.dart';
import '../../database/models/sale.dart';

class SalesProcess {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Map<String, dynamic>> analyze(Map<String, dynamic> params, int userId) async {
    try {
      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
      final sales = await _dbHelper.getSalesForUser(
        userId,
        startDate: threeMonthsAgo,
        endDate: now,
      );
      final clients = await _dbHelper.getRecentClients(userId, limit: 1000);

      // Analiza klientów
      final clientAnalysis = _analyzeClients(sales, clients);
      
      // Przygotuj sformatowaną odpowiedź
      String response = _formatAnalysisResponse(sales, clientAnalysis);
      
      return {
        'success': true,
        'message': response
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Błąd podczas analizy: $e'
      };
    }
  }

  List<Map<String, dynamic>> _analyzeClients(List<Sale> sales, List<Client> clients) {
    final analysis = <Map<String, dynamic>>[];
    
    for (var client in clients) {
      final clientSales = sales.where((sale) => sale.clientName == client.name).toList();
      if (clientSales.isEmpty) continue;

      final totalSales = clientSales.fold(0.0, (sum, sale) => sum + sale.amount);
      final lastPurchase = clientSales
          .map((s) => s.dateTime)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final daysSinceLastPurchase = DateTime.now().difference(lastPurchase).inDays;
      
      analysis.add({
        'client': client,
        'totalSales': totalSales,
        'salesCount': clientSales.length,
        'averageOrder': totalSales / clientSales.length,
        'lastPurchase': lastPurchase,
        'daysSinceLastPurchase': daysSinceLastPurchase,
        'shouldVisit': daysSinceLastPurchase > 45 && totalSales > 1000,
      });
    }

    // Sortuj według sprzedaży
    analysis.sort((a, b) => (b['totalSales'] as double).compareTo(a['totalSales'] as double));
    
    return analysis;
  }

  String _formatAnalysisResponse(List<Sale> sales, List<Map<String, dynamic>> clientAnalysis) {
    final totalSales = sales.fold(0.0, (sum, sale) => sum + sale.amount);
    final formatter = (double value) => value.toStringAsFixed(2);
    
    final topClients = clientAnalysis.take(3)
        .map((a) => "${(a['client'] as Client).name} (${formatter(a['totalSales'])} zł)")
        .join(', ');
    
    final recommendedVisits = clientAnalysis
        .where((a) => a['shouldVisit'] as bool)
        .take(3)
        .map((a) => (a['client'] as Client).name)
        .join(', ');

    return '''
    W ostatnich 3 miesiącach całkowita sprzedaż wyniosła ${formatter(totalSales)} złotych.
    
    Najlepsi klienci to: $topClients.
    
    ${recommendedVisits.isNotEmpty ? 'Zalecam odwiedzenie: $recommendedVisits.' : 'Brak pilnych rekomendacji wizyt.'}
    ''';
  }
}