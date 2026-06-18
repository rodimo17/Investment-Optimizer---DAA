import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
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
  final TextEditingController allocationCapController = TextEditingController(text: '40');
  String selectedHorizon = '1 month';
  String selectedRisk = 'Moderate';
  bool _isUpdatingRates = false;
  bool _isCalculating = false;

  final OptimizerService _optimizerService = OptimizerService();
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "en_US");

  @override
  void initState() {
    super.initState();
    _fetchRates();
    capitalController.addListener(_formatCurrency);
  }

  @override
  void dispose() {
    capitalController.removeListener(_formatCurrency);
    capitalController.dispose();
    allocationCapController.dispose();
    super.dispose();
  }

  void _formatCurrency() {
    String text = capitalController.text.replaceAll(',', '');
    if (text.isEmpty) return;
    capitalController.removeListener(_formatCurrency);
    double? value = double.tryParse(text);
    if (value != null) {
      String formatted = _currencyFormat.format(value);
      capitalController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    capitalController.addListener(_formatCurrency);
  }

  Future<void> _fetchRates() async {
    setState(() => _isUpdatingRates = true);
    await _optimizerService.fetchLatestRates();
    if (mounted) {
      setState(() => _isUpdatingRates = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bank interest rates updated in real-time!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _runOptimization() async {
    String cleanText = capitalController.text.replaceAll(',', '');
    double capital = double.tryParse(cleanText) ?? 0.0;

    if (capital <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid capital amount'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isCalculating = true);
    await Future.delayed(const Duration(milliseconds: 1500));

    final etfAllocationCapPercent = double.tryParse(allocationCapController.text) ?? 40;
    final result = _optimizerService.solveKnapsack(
      capacity: capital,
      riskPreference: selectedRisk,
      horizon: selectedHorizon,
      etfAllocationCapPercent: etfAllocationCapPercent,
    );

    setState(() => _isCalculating = false);

    if (mounted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ResultPage(optimizationResult: result),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  void _quickSet(double amount) {
    capitalController.text = amount.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: _buildBottomNav(),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isCalculating ? _buildShimmerLoading() : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputCard(),
          const SizedBox(height: 24),
          _buildActionCard(),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            Container(
              height: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.only(top: 60, bottom: 40, left: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Investment Optimizer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'DAA Project: Backtracking Solver',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (_isUpdatingRates)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: _fetchRates,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, color: Colors.deepPurple, size: 20),
              SizedBox(width: 8),
              Text(
                'Configuration',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildInputField(
            label: 'Total Capital',
            icon: Icons.account_balance_wallet_outlined,
            child: TextField(
              controller: capitalController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              decoration: const InputDecoration(
                hintText: 'e.g. 100,000',
                border: InputBorder.none,
                isDense: true,
                prefixText: '₱ ',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildQuickSetButton('10k', 10000),
              const SizedBox(width: 8),
              _buildQuickSetButton('50k', 50000),
              const SizedBox(width: 8),
              _buildQuickSetButton('100k', 100000),
            ],
          ),
          const SizedBox(height: 24),
          _buildInputField(
            label: 'Time Horizon',
            icon: Icons.calendar_today_outlined,
            child: DropdownButton<String>(
              value: selectedHorizon,
              isExpanded: true,
              underline: const SizedBox(),
              items: ['1 month', '3 months', '6 months', '1 year']
                  .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                  .toList(),
              onChanged: (v) => setState(() => selectedHorizon = v!),
            ),
          ),
          const SizedBox(height: 24),
          _buildRiskField(),
          const SizedBox(height: 24),
          _buildInputField(
            label: 'ETF Allocation Cap',
            icon: Icons.pie_chart_outline,
            child: TextField(
              controller: allocationCapController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g. 40',
                suffixText: '%',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSetButton(String label, double amount) {
    return ActionChip(
      label: Text(label),
      backgroundColor: Colors.grey[100],
      onPressed: () => _quickSet(amount),
    );
  }

  Widget _buildRiskField() {
    Color riskColor;
    if (selectedRisk == 'Conservative') riskColor = Colors.green;
    else if (selectedRisk == 'Moderate') riskColor = Colors.orange;
    else riskColor = Colors.red;

    final int maxRisk = OptimizerService.riskLimits[selectedRisk] ?? 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shield_outlined, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Risk Tolerance',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Max risk score: $maxRisk',
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButton<String>(
            value: selectedRisk,
            isExpanded: true,
            underline: const SizedBox(),
            items: ['Conservative', 'Moderate', 'Aggressive']
                .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(
                        r,
                        style: TextStyle(
                          color: r == 'Conservative'
                              ? Colors.green
                              : (r == 'Moderate' ? Colors.orange : Colors.red),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => selectedRisk = v!),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildActionCard() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _runOptimization,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
          shadowColor: Colors.deepPurple.withOpacity(0.3),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined),
            SizedBox(width: 12),
            Text(
              'RUN BACKTRACKING SOLVER',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 2) Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DetailsPage()),
          );
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