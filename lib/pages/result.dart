import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'details.dart';
import 'home.dart';
import '../services/etf_price_service.dart';
import '../services/optimizer_service.dart';
import '../models/investment_option.dart';

class ResultPage extends StatefulWidget {
  final OptimizationResult? optimizationResult;

  const ResultPage({super.key, this.optimizationResult});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "en_US");
  bool _showSteps = false;

  @override
  void initState() {
    super.initState();
    // Start animation delay for the "visualization" feel
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showSteps = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.optimizationResult;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: _buildBottomNav(context),
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(),
          if (res == null || res.allocations.isEmpty)
            const SliverFillRemaining(child: Center(child: Text('No valid combinations found.')))
          else ...[
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(child: _buildChartCard(res)),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(child: _buildMainStatsCard(res)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(child: _buildEtfPulseCard()),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Icon(Icons.psychology, size: 16, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('PURE BACKTRACKING SEARCH', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 12, letterSpacing: 1.2)),
                  ],
                ),
              ),
            ),
            if (_showSteps)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final step = res.steps[index];
                    return _buildStepItem(step, index);
                  },
                  childCount: res.steps.length,
                ),
              )
            else
              const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ],
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.deepPurple,
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
        ),
        padding: const EdgeInsets.only(top: 60, bottom: 40, left: 24, right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text('Strategy Found', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 48),
              child: Text('GLOBAL OPTIMUM ACHIEVED', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(OptimizationResult res) {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Earnings Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Stacked by Yield Efficiency', style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.deepPurple[50], borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.auto_graph, size: 14, color: Colors.deepPurple),
                    SizedBox(width: 4),
                    Text('ROI %', style: TextStyle(color: Colors.deepPurple, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: res.allocations.map((e) => e.profit).reduce((a, b) => a > b ? a : b) * 1.3,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.deepPurple.withOpacity(0.9),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final alloc = res.allocations[groupIndex];
                      return BarTooltipItem(
                        '${alloc.option.name}\n',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Total: ₱${_currencyFormat.format(alloc.profit)}\n',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.normal),
                          ),
                          TextSpan(
                            text: 'ROI: ${((alloc.profit / (alloc.amount > 0 ? alloc.amount : 1)) * 100 * 12).toStringAsFixed(1)}% p.a.',
                            style: TextStyle(color: Colors.amber[300], fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < res.allocations.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              res.allocations[value.toInt()].option.name.split(' ')[0],
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: res.allocations.asMap().entries.map((e) {
                  final alloc = e.value;
                  final hasBase = alloc.baseRateProfit > 0;
                  
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: alloc.profit,
                        width: 28,
                        borderRadius: BorderRadius.circular(6),
                        rodStackItems: [
                          BarChartRodStackItem(0, alloc.baseRateProfit, Colors.deepPurple[200]!),
                          BarChartRodStackItem(alloc.baseRateProfit, alloc.profit, Colors.deepPurple),
                        ],
                      ),
                    ],
                    showingTooltipIndicators: [0],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('High-Yield Profit', Colors.deepPurple),
              const SizedBox(width: 16),
              _buildLegendItem('Base-Rate Profit', Colors.deepPurple[200]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMainStatsCard(OptimizationResult res) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimated Profit', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
              Text('₱${_currencyFormat.format(res.totalProfit)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.green)),
            ],
          ),
          const Divider(height: 32),
          ...res.allocations.map((alloc) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)),
                      child: Icon(alloc.option.type == InvestmentType.bank ? Icons.account_balance : Icons.insights, size: 20, color: Colors.deepPurple),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.deepPurple, borderRadius: BorderRadius.circular(4)),
                              child: Text('#${alloc.rank}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Text(alloc.option.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                '${(alloc.option.annualReturnRate * 100).toStringAsFixed(1)}%',
                                style: TextStyle(color: Colors.green[700], fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('₱${_currencyFormat.format(alloc.amount)}', style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold)),
                            if (alloc.baseRateAmount > 0) ...[
                              const SizedBox(width: 4),
                              Text('(₱${_currencyFormat.format(alloc.baseRateAmount)} at ${ (alloc.option.baseReturnRate * 100).toStringAsFixed(1)}%)', style: TextStyle(color: Colors.orange[700], fontSize: 9)),
                            ],
                            const SizedBox(width: 8),
                            Icon(Icons.shield, size: 10, color: Colors.grey[400]),
                            Text(' ${alloc.option.safetyRating}/10', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                    Text('+₱${_currencyFormat.format(alloc.profit)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          _buildDaaStatsMini(res),
        ],
      ),
    );
  }

  Widget _buildDaaStatsMini(OptimizationResult res) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.psychology_outlined, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          const Text('Search Complexity: ', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w500)),
          Text('${res.statesExplored} iterations', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEtfPulseCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.deepPurple, size: 18),
              SizedBox(width: 8),
              Text('ETF Market Pulse', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Live ETF trend data from the ETF price service.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          FutureBuilder<List<EtfPriceData>>(
            future: EtfPriceService().getMonthlyPrices(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                ));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('ETF prices are unavailable right now.', style: TextStyle(color: Colors.grey, fontSize: 12));
              }

              return Column(
                children: snapshot.data!.map((price) {
                  final isPositive = price.monthlyChange >= 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.deepPurple[50],
                          child: Text(price.ticker[0], style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(price.ticker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(price.lastUpdated, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₱${price.currentPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('${isPositive ? '+' : ''}${price.monthlyChange.toStringAsFixed(2)}%', style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(TraceStep step, int index) {
    IconData icon;
    Color color;
    switch (step.type) {
      case StepType.bestFound: icon = Icons.auto_awesome; color = Colors.orange; break;
      case StepType.evaluated: icon = Icons.search; color = Colors.blue; break;
      case StepType.pruned: icon = Icons.block; color = Colors.grey; break;
      case StepType.backtrackInfo: icon = Icons.account_tree_outlined; color = Colors.teal; break;
    }
    
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 1000)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          dense: true,
          leading: Icon(icon, color: color, size: 18),
          title: Text(step.description, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          subtitle: Text(step.title, style: const TextStyle(fontSize: 10)),
          trailing: step.profit != null ? Text('+₱${step.profit!.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green)) : null,
        ),
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
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const HomePage()), (route) => false);
          if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (context) => const DetailsPage()));
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
