import 'package:flutter/material.dart';
import 'home.dart';
import '../services/etf_price_service.dart';

class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final etfService = EtfPriceService();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: _buildBottomNav(context),
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(context),
          FutureBuilder<List<EtfPriceData>>(
            future: etfService.getMonthlyPrices(),
            builder: (context, snapshot) {
              final prices = snapshot.data ?? const <EtfPriceData>[];

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Estimated free-tier API calls left: ${etfService.callsLeft}/${etfService.dailyQuota}',
                        style: const TextStyle(color: Colors.deepPurple, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    _buildCombinedTracker(prices),
                    const SizedBox(height: 24),
                    _buildInterestRatesCard(),
                    const SizedBox(height: 40),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: Colors.deepPurple,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 20),
        title: const Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Market Insights', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Text('HISTORICAL TRENDS & LIVE PRICES', style: TextStyle(color: Colors.white70, fontSize: 8, letterSpacing: 0.5)),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.deepPurple, Colors.indigo],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(Icons.show_chart, size: 200, color: Colors.white.withOpacity(0.05)),
              ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildCombinedTracker(List<EtfPriceData> prices) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
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
          const SizedBox(height: 32),
          ...prices.map((p) => _buildPriceItem(p)),
        ],
      ),
    );
  }

  Widget _buildPriceItem(EtfPriceData price) {
    final isPositive = price.monthlyChange >= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.deepPurple[50],
                radius: 20,
                child: Text(price.ticker[0], style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(price.ticker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(price.lastUpdated, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₱${price.currentPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(
                    children: [
                      Icon(isPositive ? Icons.trending_up : Icons.trending_down, size: 12, color: isPositive ? Colors.green : Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? '+' : ''}${price.monthlyChange.toStringAsFixed(2)}%',
                        style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Estimated profit is calculated as: '
            'deposit × annual rate × time horizon.',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  Widget _buildInterestRatesCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.stars, color: Colors.orange, size: 20),
              SizedBox(width: 12),
              Text('Banks List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 32),
          ),
          const SizedBox(height: 32),
          _bankRow('SeaBank', '3.25%', Icons.waves),
          _bankRow('GoTyme Bank', '3.00%', Icons.credit_card_outlined),
          _bankRow('Maya Bank', '3.00%', Icons.account_balance_wallet_outlined),
          _bankRow('UNO Digital', '3.5%', Icons.verified_user_outlined),
          _bankRow('Tonik Bank', '4.00%', Icons.savings_outlined),
          _bankRow('CIMB Bank', '2.50%', Icons.account_balance_outlined),
        ],
      ),
    );
  }

  Widget _bankRow(String name, String rate, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Text(name, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text(rate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const HomePage()), (route) => false);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Analysis'),
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: 'Details'),
        ],
      ),
    );
  }
}
