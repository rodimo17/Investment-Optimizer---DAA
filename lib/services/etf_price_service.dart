import 'dart:math';

class EtfPriceData {
  final String ticker;
  final double currentPrice;
  final double monthlyChange;
  final String lastUpdated;

  EtfPriceData({
    required this.ticker,
    required this.currentPrice,
    required this.monthlyChange,
    required this.lastUpdated,
  });
}

class EtfPriceService {
  // Hardcoded base prices (approximate market values)
  final Map<String, double> _basePrices = {
    'QQQ': 445.50,
    'VOO': 512.20,
    'VTI': 260.15,
  };

  List<EtfPriceData> getMonthlyPrices() {
    final now = DateTime.now();
    final monthName = _getMonthName(now.month);
    final year = now.year;
    
    // Seed random with the current month/year to ensure prices only change once a month
    final random = Random(now.year * 100 + now.month);

    return _basePrices.entries.map((entry) {
      // Generate a small monthly fluctuation (-2% to +5%)
      final changePercent = (random.nextDouble() * 0.07) - 0.02;
      final currentPrice = entry.value * (1 + changePercent);
      
      return EtfPriceData(
        ticker: entry.key,
        currentPrice: currentPrice,
        monthlyChange: changePercent * 100,
        lastUpdated: '$monthName $year',
      );
    }).toList();
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
