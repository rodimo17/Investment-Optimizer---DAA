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
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(child: _buildSummaryAnalytics(res)),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Icon(Icons.psychology, size: 16, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('BACKTRACKING EXECUTION TRACE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 12, letterSpacing: 1.2)),
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
                const Text('Optimal Strategy', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 48),
              child: Text('MULTI-CONSTRAINT BACKTRACKING RESULT', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 30, offset: const Offset(0, 15))],
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
                  Text('Allocation Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.grey[800], letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('Distribution by Asset', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
              const Icon(Icons.pie_chart_rounded, color: Colors.deepPurple),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: res.allocations.map((a) {
                  final color = a.option.type == InvestmentType.bank ? Colors.deepPurple : Colors.indigo;
                  return PieChartSectionData(
                    color: color,
                    value: a.amount,
                    title: '${((a.amount / (res.usedCapital > 0 ? res.usedCapital : 1)) * 100).toStringAsFixed(0)}%',
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Banks', Colors.deepPurple),
              const SizedBox(width: 24),
              _buildLegendItem('ETFs', Colors.indigo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
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
              const Text('Total Profit', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
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
                  child: Icon(alloc.option.type == InvestmentType.bank ? Icons.account_balance_rounded : Icons.insights_rounded, size: 24, color: Colors.deepPurple),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(alloc.option.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.5)),
                          const Spacer(),
                          Text('Rank #${alloc.rank}', style: TextStyle(color: Colors.deepPurple[900], fontSize: 11, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('₱${_currencyFormat.format(alloc.amount)}', style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                            child: Text('+₱${_currencyFormat.format(alloc.profit)}', style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Risk Score: ${alloc.option.riskScore}/10', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
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

  Widget _buildSummaryAnalytics(OptimizationResult res) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          _summaryRow('Used Capital', '₱${_currencyFormat.format(res.usedCapital)}'),
          const SizedBox(height: 12),
          _summaryRow('Total Risk', '${res.totalRiskScore} / ${res.maxRiskLimit}'),
          const SizedBox(height: 12),
          _summaryRow('Bank Allocation', '${res.bankAllocationPercent.toStringAsFixed(1)}%'),
          const SizedBox(height: 12),
          _summaryRow('ETF Allocation', '${res.etfAllocationPercent.toStringAsFixed(1)}%'),
          const SizedBox(height: 12),
          _summaryRow('Floor Met', res.metDiversificationFloor ? 'YES' : 'NO', isGreen: res.metDiversificationFloor),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(color: isGreen ? Colors.greenAccent : Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDaaStatsMini(OptimizationResult res) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue[100]!)),
      child: Row(
        children: [
          const Icon(Icons.psychology_outlined, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          const Text('Recursive Iterations: ', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w500)),
          Text('${res.statesExplored}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
          const Spacer(),
          Text('Pruned: ${res.branchesPruned}', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 10)),
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
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: color, size: 18),
        title: Text(step.description, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        subtitle: Text(step.title, style: const TextStyle(fontSize: 9)),
        trailing: step.profit != null ? Text('+₱${step.profit!.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green)) : null,
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
