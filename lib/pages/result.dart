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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.deepPurple,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage()));
          }
          if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const DetailsPage()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.insert_chart_outlined), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_customize), label: 'Browse'),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              color: Colors.deepPurple,
              padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
              child: const Column(
                children: [
                  Text(
                    'Optimization Results',
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'BACKTRACKING ANALYSIS',
                    style: TextStyle(color: Colors.white60, fontSize: 12, letterSpacing: 2),
                  ),
                ],
              ),
            ),
          ),

          if (optimizationResult == null || optimizationResult!.allocations.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No valid combinations found.')),
            )
          else ...[
            // Main Recommendation
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(child: _buildRecommendationCard()),
            ),

            // Visual Trace Section
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'ALGORITHM STEP-BY-STEP',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13, letterSpacing: 1.1),
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final step = optimizationResult!.steps[index];
                  return _buildStepItem(step);
                },
                childCount: optimizationResult!.steps.length,
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Best Investment Strategy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 24),
          ...optimizationResult!.allocations.map((alloc) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.deepPurple[50],
                      child: Icon(
                        alloc.option.type == InvestmentType.bank ? Icons.account_balance : Icons.trending_up,
                        color: Colors.deepPurple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(alloc.option.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('₱${alloc.amount.toStringAsFixed(0)} allocation', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('+₱${alloc.profit.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
                  ],
                ),
              )),
          const Divider(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Return:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  '₱${optimizationResult!.totalProfit.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 22),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStepItem(TraceStep step) {
    IconData icon;
    Color color;
    switch (step.type) {
      case StepType.bestFound:
        icon = Icons.star;
        color = Colors.orange;
        break;
      case StepType.evaluated:
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case StepType.pruned:
        icon = Icons.highlight_off;
        color = Colors.grey;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: step.type == StepType.bestFound ? Colors.orange[200]! : Colors.transparent),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          step.description,
          style: TextStyle(
            fontWeight: step.type == StepType.bestFound ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
            decoration: step.type == StepType.pruned ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(step.title, style: const TextStyle(fontSize: 11)),
        trailing: step.profit != null
            ? Text(
                '₱${step.profit!.toStringAsFixed(0)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 13),
              )
            : null,
      ),
    );
  }
}
