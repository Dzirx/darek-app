import '../../database/database_helper.dart';

class SalesProcess {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Map<String, dynamic>> analyze(Map<String, dynamic> params, int userId) async {
    try {
      final period = params['period'] ?? 'month';
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate = now;

      switch (period) {
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'year':
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = now.subtract(const Duration(days: 30));
      }

      final total = await _dbHelper.getTotalSalesForPeriod(
        userId,
        startDate,
        endDate,
      );

      return {
        'success': true,
        'total': total,
        'message': 'Całkowita sprzedaż w tym okresie wynosi ${total.toStringAsFixed(2)} złotych',
        'period': period,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };
    } catch (e) {
      print('Error analyzing sales: $e');
      return {
        'success': false,
        'message': 'Błąd podczas analizy sprzedaży: $e',
      };
    }
  }
}