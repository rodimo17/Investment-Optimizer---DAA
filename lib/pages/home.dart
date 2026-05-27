import 'package:flutter/material.dart';
import 'details.dart';
import 'result.dart';
import '../services/optimizer_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController capitalController = TextEditingController();
  final TextEditingController amountController = TextEditingController(); // Using this for "Max Diversification" count
  String selectedHorizon = '1 month';
  String selectedRisk = 'Moderate';

  final OptimizerService _optimizerService = OptimizerService();

  void _runOptimization() {
    double capital = double.tryParse(capitalController.text) ?? 0.0;

    if (capital <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid capital amount')),
      );
      return;
    }

    // Call the Knapsack Backtracking Solver
    final result = _optimizerService.solveKnapsack(
      capacity: capital,
      riskPreference: selectedRisk,
      timeHorizon: selectedHorizon,
       maxItems: int.tryParse(amountController.text),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(optimizationResult: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.deepPurple,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        currentIndex: 1, // 1 = home.dart or home page - highlighted currently

        onTap: (index) {
          if (index == 0) {
            // We can't go to result page without a result, so maybe just show empty or run with defaults
            _runOptimization();
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
          // Header 
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
                SizedBox(height: 4),
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
                  'CALCULATE',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable Body ──────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Your Inputs ────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Inputs',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const Divider(),

                        // Total Capital
                        Row(
                          children: [
                            const SizedBox(
                              width: 120,
                              child: Text(
                                'Total Capital:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: capitalController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'Insert Amount',
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),

                        // Time Horizon
                        Row(
                          children: [
                            const SizedBox(
                              width: 120,
                              child: Text(
                                'Time Horizon:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              child: DropdownButton<String>(
                                value: selectedHorizon,
                                isExpanded: true,
                                underline: const SizedBox(),
                                items: ['1 month', '3 months', '6 months', '1 year']
                                    .map((h) => DropdownMenuItem(
                                          value: h,
                                          child: Text(h),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  setState(() {
                                    selectedHorizon = v!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const Divider(),

                        // Risk Level
                        Row(
                          children: [
                            const SizedBox(
                              width: 120,
                              child: Text(
                                'Risk Level:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              child: DropdownButton<String>(
                                value: selectedRisk,
                                isExpanded: true,
                                underline: const SizedBox(),
                                items: ['Conservative', 'Moderate', 'Aggressive']
                                    .map((r) => DropdownMenuItem(
                                          value: r,
                                          child: Text(r),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  setState(() {
                                    selectedRisk = v!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const Divider(),

                        // Amount (Max Diversification)
                        Row(
                          children: [
                            const SizedBox(
                              width: 120,
                              child: Text(
                                'Max Options:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: amountController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 3',
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── View ──────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'View',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _runOptimization,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Backtracking Trace',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

