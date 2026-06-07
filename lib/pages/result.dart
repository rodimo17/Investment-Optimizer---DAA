import 'package:flutter/material.dart';
import 'details.dart';
import 'home.dart';
import '../services/optimizer_service.dart';

class ResultPage extends StatelessWidget {
  final OptimizationResult? optimizationResult;

  const ResultPage({super.key, this.optimizationResult});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.deepPurple,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        currentIndex: 0, // 0 = result.dart or result page - highlighted currently

        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DetailsPage()),
            );
          }
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart_outlined),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize),
            label: 'Browse',
          ),
        ],
      ),

      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.deepPurple,
            padding: const EdgeInsets.only(
              top: 50,
              bottom: 30,
              left: 20,
              right: 20,
            ),
            child: const Column(
              children: [
                Text(
                  'Investment Optimizer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'RESULTS',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: optimizationResult == null
                ? const Center(child: Text('No results to display. Run optimization from Home.'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Best Selection
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recommended Allocation',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const Divider(),
                              ...optimizationResult!.selectedOptions.map((opt) => ListTile(
                                    title: Text(opt.name),
                                    trailing: Text('₱${(opt.minInvestment * opt.annualReturnRate).toStringAsFixed(0)} profit'),
                                    subtitle: Text(opt.type.name.toUpperCase()),
                                  )),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Projected Profit:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    '₱${optimizationResult!.totalProfit.toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Backtracking Trace
                        const Text(
                          'Knapsack Backtracking Trace',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: optimizationResult!.trace
                                .map((step) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '> $step',
                                        style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace'),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

