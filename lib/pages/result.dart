import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'details.dart';
import 'home.dart';
import '../services/optimizer_service.dart';
import '../models/investment_option.dart';

class ResultPage extends StatelessWidget {
  final OptimizationResult? optimizationResult;

  const ResultPage({super.key, this.optimizationResult});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: _buildBottomNav(context),
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(),
          if (optimizationResult == null || optimizationResult!.allocations.isEmpty)
            const SliverFillRemaining(child: Center(child: Text('No valid combinations found.')))
          else ...[
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(child: _buildChartCard()),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(child: _buildMainStatsCard()),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Text('BACKTRACKING ANALYSIS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12, letterSpacing: 1.2)),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildStepItem(optimizationResult!.steps[index]),
                childCount: optimizationResult!.steps.length,
              ),
            ),
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
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Optimization Complete', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('VIEWING BEST BACKTRACKING COMBO', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: optimizationResult!.allocations.asMap().entries.map((e) {
                  final colors = [Colors.deepPurple, Colors.orange, Colors.blue, Colors.green];
                  return PieChartSectionData(
                    color: colors[e.key % colors.length],
                    value: e.value.amount,
                    title: '${(e.value.amount / (optimizationResult!.allocations.fold(0.0, (s, i) => s + i.amount)) * 100).toStringAsFixed(0)}%',
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: optimizationResult!.allocations.asMap().entries.map((e) {
                final colors = [Colors.deepPurple, Colors.orange, Colors.blue, Colors.green];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[e.key % colors.length], shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.value.option.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStatsCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Return', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
              Text('₱${optimizationResult!.totalProfit.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.green)),
            ],
          ),
          const Divider(height: 32),
          ...optimizationResult!.allocations.map((alloc) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    CircleAvatar(backgroundColor: Colors.deepPurple[50], radius: 18, child: Icon(alloc.option.type == InvestmentType.bank ? Icons.account_balance : Icons.show_chart, size: 18, color: Colors.deepPurple)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(alloc.option.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('₱${alloc.amount.toStringAsFixed(0)} allocated', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('₱${alloc.profit.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          _buildDaaStatsMini(),
        ],
      ),
    );
  }

  Widget _buildDaaStatsMini() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.psychology, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Text('Search Space: ', style: TextStyle(color: Colors.blue[800], fontSize: 12)),
          Text('${optimizationResult!.statesExplored} states', style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStepItem(TraceStep step) {
    IconData icon;
    Color color;
    switch (step.type) {
      case StepType.bestFound: icon = Icons.star; color = Colors.orange; break;
      case StepType.evaluated: icon = Icons.check_circle; color = Colors.green; break;
      case StepType.pruned: icon = Icons.remove_circle_outline; color = Colors.grey; break;
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 20),
        title: Text(step.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        subtitle: Text(step.title, style: const TextStyle(fontSize: 11)),
        trailing: step.profit != null ? Text('₱${step.profit!.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)) : null,
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
      currentIndex: 0,
      onTap: (index) {
        if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage()));
        if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (context) => const DetailsPage()));
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Analysis'),
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: 'Details'),
      ],
    );
  }
}
