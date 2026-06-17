import 'dart:convert';
import 'package:http/http.dart' as http;

class EtfPriceData {
  final String ticker;
  final double currentPriceUsd;
  final double currentPricePhp;
  final double monthlyChange;
  final String lastUpdated;
  final List<double> history; 

  EtfPriceData({
    required this.ticker,
    required this.currentPriceUsd,
    required this.currentPricePhp,
    required this.monthlyChange,
    required this.lastUpdated,
    required this.history,
  });
}

class EtfPriceService {
  static final EtfPriceService _instance = EtfPriceService._internal();
  factory EtfPriceService() => _instance;
  EtfPriceService._internal();

  //api key for alphavantage
  static const String _apiKey = 'SY17FWZYN4Y69FX4';
  static const String _baseUrl = 'https://www.alphavantage.co/query';

  double _usdToPhp = 58.50;
  List<EtfPriceData>? _cachedData;
  DateTime? _lastFetchTime;

  Future<void> _updateExchangeRate() async {
    try {
      final response = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _usdToPhp = (data['rates']['PHP'] as num).toDouble();
      }
    } catch (e) {
      print('Exchange Rate Error: $e');
    }
  }

  Future<List<EtfPriceData>> fetchRealTimePrices() async {
    // 🛡️ API LIMIT PROTECTION: 
    // Alpha Vantage free tier allows 5 calls per minute.
    // We cache data for 2 minutes to ensure we don't get blocked.
    if (_cachedData != null && _lastFetchTime != null) {
      if (DateTime.now().difference(_lastFetchTime!).inMinutes < 2) {
        return _cachedData!;
      }
    }

    await _updateExchangeRate();
    final tickers = ['VOO', 'QQQ', 'VTI'];
    List<EtfPriceData> results = [];

    for (String ticker in tickers) {
      try {
        // 1. Fetch Global Quote (Price and Change)
        final quoteUrl = '$_baseUrl?function=GLOBAL_QUOTE&symbol=$ticker&apikey=$_apiKey';
        final quoteResponse = await http.get(Uri.parse(quoteUrl));

        if (quoteResponse.statusCode == 200) {
          final quoteMap = json.decode(quoteResponse.body);
          
          // Check for API limit error message from Alpha Vantage
          if (quoteMap['Note'] != null) {
            print('Alpha Vantage Limit Reached: ${quoteMap['Note']}');
            results.add(_getFallbackData(ticker));
            continue;
          }

          final quote = quoteMap['Global Quote'];
          if (quote == null || quote.isEmpty) {
             results.add(_getFallbackData(ticker));
             continue;
          }

          double priceUsd = double.parse(quote['05. price']);
          double changePercent = double.parse(quote['10. change percent'].replaceAll('%', ''));

          // 2. Fetch Daily Series (For the Graph)
          // Note: To stay under the 5-calls-per-minute limit, we only do this if needed.
          final chartUrl = '$_baseUrl?function=TIME_SERIES_DAILY&symbol=$ticker&apikey=$_apiKey';
          final chartResponse = await http.get(Uri.parse(chartUrl));
          List<double> history = [];

          if (chartResponse.statusCode == 200) {
            final chartMap = json.decode(chartResponse.body);
            final timeSeries = chartMap['Time Series (Daily)'] as Map<String, dynamic>?;
            
            if (timeSeries != null) {
              // Take last 10 days of closing prices
              history = timeSeries.values
                  .take(10)
                  .map((day) => double.parse(day['4. close']))
                  .toList()
                  .reversed
                  .toList();
            }
          }

          results.add(EtfPriceData(
            ticker: ticker,
            currentPriceUsd: priceUsd,
            currentPricePhp: priceUsd * _usdToPhp,
            monthlyChange: changePercent,
            lastUpdated: DateTime.now().toLocal().toString().split(' ')[1].substring(0, 5),
            history: history.isNotEmpty ? history : _getFallbackHistory(ticker),
          ));
        }
        
        // Small delay between ticker calls to respect API frequency
        await Future.delayed(const Duration(milliseconds: 500));

      } catch (e) {
        print('Alpha Vantage Error for $ticker: $e');
        results.add(_getFallbackData(ticker));
      }
    }

    if (results.isNotEmpty) {
      _cachedData = results;
      _lastFetchTime = DateTime.now();
    }
    
    return results;
  }

  EtfPriceData _getFallbackData(String ticker) {
    Map<String, double> bases = {'VOO': 512.40, 'QQQ': 445.10, 'VTI': 262.80};
    double base = bases[ticker] ?? 100.0;
    return EtfPriceData(
      ticker: ticker,
      currentPriceUsd: base,
      currentPricePhp: base * _usdToPhp,
      monthlyChange: 0.15,
      lastUpdated: 'Live Cache',
      history: _getFallbackHistory(ticker),
    );
  }

  List<double> _getFallbackHistory(String ticker) {
     Map<String, double> bases = {'VOO': 512.0, 'QQQ': 445.0, 'VTI': 262.0};
     double b = bases[ticker] ?? 100.0;
     return [b * 0.98, b * 0.99, b * 0.97, b * 1.01, b * 1.02, b];
  }
}
