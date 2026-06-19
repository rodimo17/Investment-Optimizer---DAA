import 'dart:math';

class EtfPriceData {
  final String ticker;
  final double currentPrice;
  final double monthlyChange;
  final String lastUpdated;
  final List<double> history; // Last 6 months

  EtfPriceData({
    required this.ticker,
    required this.currentPrice,
    required this.monthlyChange,
    required this.lastUpdated,
    required this.history,
  });
}

class EtfPriceService {
  final Map<String, double> _basePrices = {
    'QQQ': 44807.51,
    'VOO': 41630.66,
    'VTI': 22384.40,
  };

  List<EtfPriceData> getMonthlyPrices() {
    final now = DateTime.now();
    final random = Random(now.year * 100 + now.month);

    return _basePrices.entries.map((entry) {
      final changePercent = (random.nextDouble() * 0.07) - 0.02;
      final currentPrice = entry.value * (1 + changePercent);
      
      // Generate 6 months of historical data
      List<double> history = [];
      double tempPrice = entry.value;
      for (int i = 0; i < 6; i++) {
        tempPrice = tempPrice * (1 + (random.nextDouble() * 0.05 - 0.02));
        history.add(tempPrice);
      }

      return EtfPriceData(
        ticker: entry.key,
        currentPrice: currentPrice,
        monthlyChange: changePercent * 100,
        lastUpdated: _getMonthName(now.month) + ' ${now.year}',
        history: history.reversed.toList(),
      );
    }).toList();
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
