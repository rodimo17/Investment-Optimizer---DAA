import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'details.dart';
import 'home.dart';
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
      height: 380,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profit Analysis',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.grey[800],
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Optimized Yield',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: const Icon(Icons.insights_rounded, size: 20, color: Colors.deepPurple),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: res.allocations.map((e) => e.profit).reduce((a, b) => a > b ? a : b) * 1.4,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.white,
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final alloc = res.allocations[groupIndex];
                      return BarTooltipItem(
                        '₱${_currencyFormat.format(alloc.profit)}\n',
                        TextStyle(color: Colors.grey[900], fontWeight: FontWeight.bold, fontSize: 14),
                        children: [
                          TextSpan(
                            text: '${((alloc.profit / (alloc.amount > 0 ? alloc.amount : 1)) * 100 * 12).toStringAsFixed(2)}% ROI',
                            style: const TextStyle(color: Colors.deepPurple, fontSize: 11, fontWeight: FontWeight.w600),
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
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < res.allocations.length) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 12,
                            child: Text(
                              res.allocations[value.toInt()].option.name.split(' ')[0],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: res.allocations.map((e) => e.profit).reduce((a, b) => a > b ? a : b) / 3,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[100]!,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                barGroups: res.allocations.asMap().entries.map((e) {
                  final alloc = e.value;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: alloc.profit,
                        width: 32,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        rodStackItems: [
                          BarChartRodStackItem(0, alloc.baseRateProfit, Colors.deepPurple.withOpacity(0.2)),
                          BarChartRodStackItem(alloc.baseRateProfit, alloc.profit, Colors.deepPurple),
                        ],
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple, Colors.deepPurple.withOpacity(0.8)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutQuart,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Elite Yield', Colors.deepPurple),
              const SizedBox(width: 24),
              _buildLegendItem('Base Rate', Colors.deepPurple.withOpacity(0.2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
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
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[100]!),
                      ),
                      child: Icon(
                        alloc.option.type == InvestmentType.bank ? Icons.account_balance_rounded : Icons.insights_rounded,
                        size: 24,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                alloc.option.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.5),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  alloc.option.typeLabel,
                                  style: const TextStyle(
                                    color: Colors.deepPurple,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Rank #${alloc.rank}',
                                style: TextStyle(color: Colors.deepPurple[900], fontSize: 11, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '₱${_currencyFormat.format(alloc.amount)}',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (alloc.baseRateAmount > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(+₱${_currencyFormat.format(alloc.baseRateAmount)} Base)',
                                  style: TextStyle(color: Colors.orange[800], fontSize: 10, fontWeight: FontWeight.w500),
                                ),
                              ],
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '+₱${_currencyFormat.format(alloc.profit)}',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Risk Index: ${alloc.option.riskScore}/10',
                                style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 8),
                              Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(
                                alloc.option.riskScore <= 3 ? 'LOW RISK' : (alloc.option.riskScore <= 7 ? 'MED RISK' : 'HIGH RISK'),
                                style: TextStyle(
                                  color: alloc.option.riskScore <= 3 ? Colors.teal : (alloc.option.riskScore <= 7 ? Colors.orange[800] : Colors.redAccent),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Est. Profit',
                                style: TextStyle(color: Colors.grey[400], fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50], 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!),
      ),
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
