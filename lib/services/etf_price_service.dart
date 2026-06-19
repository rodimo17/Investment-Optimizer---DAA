import 'dart:convert';
import 'package:http/http.dart' as http;
import 'etf_price_service_og.dart' as fallback_service;

class EtfPriceData {
  final String ticker;
  final double currentPrice;
  final double monthlyChange;
  final String lastUpdated;
  final List<double> history;

  EtfPriceData({
    required this.ticker,
    required this.currentPrice,
    required this.monthlyChange,
    required this.lastUpdated,
    required this.history,
  });
}

class EtfPriceService {
  static const String _apiKey = 'RQ0DSMW7JAY59LEK';
  static const String _baseUrl = 'https://www.alphavantage.co/query';
  static const List<String> tickers = ['QQQ', 'VOO', 'VTI'];
  static const int _dailyQuota = 25;

  static int _callsMade = 0;
  static String _callDate = '';

  int get callsMade => _callsMade;
  int get callsLeft => _dailyQuota - _callsMade;
  int get dailyQuota => _dailyQuota;

  void _resetIfNewDay() {
    String today = DateTime.now().toString().substring(0, 10); // "YYYY-MM-DD"
    if (_callDate != today) {
      _callsMade = 0;
      _callDate = today;
    }
  }

  Future<EtfPriceData> fetchMonthlyPrice(String ticker) async {
    _resetIfNewDay();

    final uri = Uri.parse(
      '$_baseUrl?function=TIME_SERIES_MONTHLY&symbol=$ticker&apikey=$_apiKey',
    );

    final response = await http.get(uri);
    _callsMade++;

    if (response.statusCode != 200) {
      throw Exception('[$ticker] HTTP error: ${response.statusCode}');
    }

    final json = jsonDecode(response.body);

    if (json.containsKey('Error Message')) {
      throw Exception('[$ticker] API error: ${json['Error Message']}');
    }

    if (json.containsKey('Note')) {
      throw Exception('[$ticker] Rate limit hit: ${json['Note']}');
    }

    final Map<String, dynamic> timeSeries = json['Monthly Time Series'];
    final entries = timeSeries.entries.toList();

    List<double> history = [];
    for (int i = 0; i < 6; i++) {
      history.add(double.parse(entries[i].value['4. close']));
    }

    final currentPrice = history[0];
    final previousPrice = history[1];
    final monthlyChange = ((currentPrice - previousPrice) / previousPrice) * 100;

    final rawDate = entries[0].key;
    final dateParts = rawDate.split('-');
    final lastUpdated = '${_monthName(int.parse(dateParts[1]))} ${dateParts[0]}';

    return EtfPriceData(
      ticker: ticker,
      currentPrice: currentPrice,
      monthlyChange: monthlyChange,
      lastUpdated: lastUpdated,
      history: history,
    );
  }

  Future<List<EtfPriceData>> getMonthlyPrices() async {
    List<EtfPriceData> results = [];

    for (final ticker in tickers) {
      try {
        final data = await fetchMonthlyPrice(ticker);
        results.add(data);
      } catch (e) {
        final fallbackList =
            fallback_service.EtfPriceService().getMonthlyPrices();

        fallback_service.EtfPriceData? fallback;
        for (final item in fallbackList) {
          if (item.ticker == ticker) {
            fallback = item;
            break;
          }
        }

        fallback ??= fallback_service.EtfPriceData(
          ticker: ticker,
          currentPrice: 0,
          monthlyChange: 0,
          lastUpdated: 'Fallback',
          history: [0, 0, 0, 0, 0, 0],
        );

        results.add(EtfPriceData(
          ticker: fallback.ticker,
          currentPrice: fallback.currentPrice,
          monthlyChange: fallback.monthlyChange,
          lastUpdated: fallback.lastUpdated,
          history: fallback.history,
        ));
      }
    }

    return results;
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}