import 'package:flutter/material.dart';
import '../services/optimizer_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController capitalController = TextEditingController(text: '100000');
  final TextEditingController monthsController = TextEditingController(text: '12');
  String selectedRisk = 'Medium — balanced';

  final OptimizerService _optimizerService = OptimizerService();
  OptimizationResult? _result;

  void _runOptimization() {
    double capital = double.tryParse(capitalController.text) ?? 0.0;
    int months = int.tryParse(monthsController.text) ?? 12;

    if (capital <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid capital amount')),
      );
      return;
    }

    setState(() {
      _result = _optimizerService.findBestCombo(
        capital: capital,
        riskAppetite: selectedRisk,
        months: months,
      );
    });
  }

  String formatMoney(double value) {
    return '₱${value.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Investment combo finder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Finds the best 1 bank + 1 ETF pairing for your capital using backtracking knapsack.',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              const SizedBox(height: 24),
              _buildInputSection(),
              const SizedBox(height: 24),
              _buildActionButton(),
              const SizedBox(height: 32),
              if (_result != null) ...[
                _buildTraceSection(),
                const SizedBox(height: 32),
                _buildRecommendationSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildInputLabel('Capital (₱)', capitalController),
          const SizedBox(height: 16),
          _buildDropdownLabel('Risk appetite'),
          const SizedBox(height: 16),
          _buildInputLabel('Months to hold', monthsController),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _runOptimization,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Text('Find best combination', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        label: const Icon(Icons.north_east, size: 18),
      ),
    );
  }

  Widget _buildInputLabel(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownLabel(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedRisk,
              isExpanded: true,
              items: ['Low — conservative', 'Medium — balanced', 'High — aggressive'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => selectedRisk = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTraceSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Backtracking trace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 16),
          ..._result!.trace.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(line, style: TextStyle(color: line.startsWith('X') ? Colors.grey : Colors.black87, fontSize: 13, fontFamily: 'monospace')),
              )),
          const SizedBox(height: 12),
          Text(
            'Best combo: ${_result!.bank?.name ?? "None"} + ${_result!.etf?.name ?? "None"}',
            style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection() {
    double capital = double.tryParse(capitalController.text) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recommended: ${_result!.bank?.name ?? "N/A"} + ${_result!.etf?.name ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildResultCard('Total return', formatMoney(_result!.totalReturn)),
            _buildResultCard('Final Value', formatMoney(capital + _result!.totalReturn)),
            _buildResultCard('Bank Allocation', formatMoney(capital / 2)),
            _buildResultCard('ETF Allocation', formatMoney(capital / 2)),
          ],
        ),
      ],
    );
  }

  Widget _buildResultCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepPurple[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: Colors.deepPurple[700], fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        ],
      ),
    );
  }
}
