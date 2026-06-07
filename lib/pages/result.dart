import 'package:flutter/material.dart';
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
              sliver: SliverToBoxAdapter(child: _buildMainStatsCard()),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ALGORITHM EXECUTION LOG', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12, letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    _buildDaaStatsCard(),
                    const SizedBox(height: 12),
                  ],
                ),
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
        color: Colors.deepPurple,
        padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
        child: const Column(
          children: [
            Text('Optimization Complete', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('RESULT ANALYSIS & DAA LOGS', style: TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStatsCard() {
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
              Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text('Optimized Allocation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const Divider(height: 32),
          ...optimizationResult!.allocations.map((alloc) => _buildAllocationItem(alloc)),
          const Divider(height: 32),
          _buildProfitSummary(),
        ],
      ),
    );
  }

  Widget _buildAllocationItem(Allocation alloc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.deepPurple[50],
            child: Icon(alloc.option.type == InvestmentType.bank ? Icons.account_balance : Icons.trending_up, color: Colors.deepPurple, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alloc.option.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Allocated: ₱${alloc.amount.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+₱${alloc.profit.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              const Text('profit', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfitSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total Estimated Return:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(
            '₱${optimizationResult!.totalProfit.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildDaaStatsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue[100]!)),
      child: Row(
        children: [
          const Icon(Icons.psychology, color: Colors.blue),
          const SizedBox(width: 12),
          Text('Search Space Explored: ', style: TextStyle(color: Colors.blue[800], fontSize: 13)),
          Text('${optimizationResult!.statesExplored} recursive states', style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold, fontSize: 13)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
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
      currentIndex: 0,
      onTap: (index) {
        if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage()));
        if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (context) => const DetailsPage()));
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analysis'),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: 'Details'),
      ],
    );
  }
}
