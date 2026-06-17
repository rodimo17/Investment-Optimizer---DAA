import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'home.dart';
import '../services/etf_price_service.dart';
import '../services/optimizer_service.dart';
import '../models/investment_option.dart';

class DetailsPage extends StatefulWidget {
  const DetailsPage({super.key});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final EtfPriceService _etfService = EtfPriceService();
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "en_US");
  late Future<List<EtfPriceData>> _priceFuture;

  @override
  void initState() {
    super.initState();
    _priceFuture = _etfService.fetchRealTimePrices();
  }

  void _refreshData() {
    setState(() {
      _priceFuture = _etfService.fetchRealTimePrices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: _buildBottomNav(context),
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(context),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FutureBuilder<List<EtfPriceData>>(
                  future: _priceFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildShimmerTracker();
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No live data available.'));
                    }
                    return _buildCombinedTracker(snapshot.data!);
                  },
                ),
                const SizedBox(height: 24),
                _buildInterestRatesCard(),
                const SizedBox(height: 40),
              ]),
            ),
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
            Text('REAL-TIME GLOBAL DATA', style: TextStyle(color: Colors.white70, fontSize: 8, letterSpacing: 0.5)),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4A148C), Color(0xFF1A237E)],
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
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _refreshData,
        ),
      ],
    );
  }

  Widget _buildShimmerTracker() {
    return Shimmer.fromColors(
      baseColor: Colors.white,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 400,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
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
                child: Text('LIVE DATA', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 10)),
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
                    Text('Updated: ${price.lastUpdated}', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₱${_currencyFormat.format(price.currentPricePhp)}', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A237E), letterSpacing: -0.5)),
                  Text('\$${price.currentPriceUsd.toStringAsFixed(2)} USD', 
                    style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down, 
                        size: 20, color: isPositive ? Colors.greenAccent[700] : Colors.redAccent),
                      Text(
                        '${isPositive ? '+' : ''}${price.monthlyChange.toStringAsFixed(2)}%',
                        style: TextStyle(color: isPositive ? Colors.greenAccent[700] : Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
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
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          (isPositive ? Colors.green : Colors.red).withOpacity(0.2),
                          (isPositive ? Colors.green : Colors.red).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  Widget _buildInterestRatesCard() {
    final optimizerService = OptimizerService();
    final banks = optimizerService.allOptions
        .where((opt) => opt.type == InvestmentType.bank)
        .toList();
    
    // Sort by return rate for better "Scoring" feel
    banks.sort((a, b) => b.annualReturnRate.compareTo(a.annualReturnRate));

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
              Icon(Icons.stars_rounded, color: Colors.orange, size: 22),
              SizedBox(width: 12),
              Text('Investment Scoring', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.5)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 34, top: 4),
            child: Text('LIVE BANK RATES & SAFETY METRICS', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ),
          const SizedBox(height: 32),
          ...banks.map((bank) => _bankRow(
                bank.name,
                '${(bank.annualReturnRate * 100).toStringAsFixed(2)}%',
                bank.safetyRating,
                bank.liquidityScore,
                bank.name.contains('SeaBank') ? Icons.waves : 
                bank.name.contains('Maya') ? Icons.account_balance_wallet_outlined :
                Icons.account_balance_rounded,
              )),
        ],
      ),
    );
  }

  Widget _bankRow(String name, String rate, int safety, int liquidity, IconData icon) {
    // Calculate a visual score based on return, safety and liquidity
    final double scoreValue = (safety + liquidity + (double.tryParse(rate.replaceAll('%', '')) ?? 0)) / 25;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: const Color(0xFF4A148C)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildMetric(Icons.shield_rounded, 'Safety', '$safety/10'),
                        const SizedBox(width: 16),
                        _buildMetric(Icons.speed_rounded, 'Liquid', '$liquidity/10'),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(rate, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                  ),
                  const SizedBox(height: 6),
                  Text('APY YIELD', style: TextStyle(color: Colors.grey[400], fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: scoreValue.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[100],
              color: const Color(0xFF4A148C).withOpacity(0.6),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
        ],
      ),
    );
  }

  Widget _buildMetric(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
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
