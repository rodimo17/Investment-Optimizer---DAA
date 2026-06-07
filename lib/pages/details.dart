import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'home.dart';
import 'result.dart';
import '../services/etf_price_service.dart';

class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final etfService = EtfPriceService();
    final etfPrices = etfService.getMonthlyPrices();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultPage()));
          if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage()));
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Analysis'),
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: 'Details'),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            padding: const EdgeInsets.only(top: 60, bottom: 40, left: 24, right: 24),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Market Insights', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('HISTORICAL TRENDS & LIVE PRICES', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildCombinedTracker(etfPrices),
                  const SizedBox(height: 20),
                  _buildInterestRatesCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedTracker(List<EtfPriceData> prices) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ETF Market Performance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(20)),
                child: Text('LIVE ₱', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...prices.map((p) => _buildExpandablePriceItem(p)),
        ],
      ),
    );
  }

  Widget _buildExpandablePriceItem(EtfPriceData price) {
    final isPositive = price.monthlyChange >= 0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: Colors.deepPurple[50], radius: 18, child: Text(price.ticker[0], style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold))),
                const SizedBox(width: 12),
                Text(price.ticker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₱${price.currentPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${isPositive ? '+' : ''}${price.monthlyChange.toStringAsFixed(2)}%', style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: price.history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                  isCurved: true,
                  color: isPositive ? Colors.green : Colors.red,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: (isPositive ? Colors.green : Colors.red).withAlpha(20)),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildInterestRatesCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Digital Bank Interest Rates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),
          _bankRow('Maya Bank', '8.00%', Icons.account_balance_wallet_outlined),
          _bankRow('Tonik Bank', '5.00%', Icons.savings_outlined),
          _bankRow('GoTyme Bank', '4.00%', Icons.credit_card_outlined),
          _bankRow('CIMB Bank', '4.50%', Icons.account_balance_outlined),
        ],
      ),
    );
  }

  Widget _bankRow(String name, String rate, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(rate, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        ],
      ),
    );
  }
}
