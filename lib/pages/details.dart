import 'package:flutter/material.dart';
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
        backgroundColor: Colors.deepPurple,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultPage()));
          if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage()));
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: 'Details'),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.deepPurple,
            padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
            child: const Column(
              children: [
                Text('Market Insights', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('REAL-TIME MARKET DATA (MONTHLY)', style: TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 2)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceTrackerCard(etfPrices),
                  const SizedBox(height: 20),
                  _buildRatesCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceTrackerCard(List<EtfPriceData> prices) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.query_stats, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text('ETF Price Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)),
                child: Text('Live', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Last updated: ${prices[0].lastUpdated}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          const Divider(height: 32),
          ...prices.map((p) => _buildPriceItem(p)),
        ],
      ),
    );
  }

  Widget _buildPriceItem(EtfPriceData price) {
    final isPositive = price.monthlyChange >= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: Colors.blue[50], radius: 18, child: Text(price.ticker[0], style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(price.ticker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text('Monthly Tracker', style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${price.currentPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                children: [
                  Icon(isPositive ? Icons.trending_up : Icons.trending_down, color: isPositive ? Colors.green : Colors.red, size: 14),
                  const SizedBox(width: 4),
                  Text('${isPositive ? '+' : ''}${price.monthlyChange.toStringAsFixed(2)}%', style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance, color: Colors.deepPurple, size: 20),
              SizedBox(width: 8),
              Text('Interest Rate Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const Divider(height: 32),
          _bankRow('Maya Bank', '8.00%'),
          _bankRow('Tonik Bank', '5.00%'),
          _bankRow('GoTyme Bank', '4.00%'),
          _bankRow('CIMB Bank', '4.50%'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 16),
                SizedBox(width: 12),
                Expanded(child: Text('Rates are per annum and subject to change by banks.', style: TextStyle(color: Colors.orange, fontSize: 11))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankRow(String name, String rate) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(rate, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        ],
      ),
    );
  }
}
