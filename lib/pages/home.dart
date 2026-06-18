import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'details.dart';
import 'result.dart';
import '../services/optimizer_service.dart';
import '../models/investment_option.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final TextEditingController capitalController = TextEditingController();
  final TextEditingController amountController = TextEditingController(text: '3'); 
  String selectedHorizon = '1 month';
  String selectedRisk = 'Moderate';
  bool _isCalculating = false;

  late AnimationController _buttonScaleController;
  final OptimizerService _optimizerService = OptimizerService();
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "en_US");

  double get _currentCapital => double.tryParse(capitalController.text.replaceAll(',', '')) ?? 0.0;

  @override
  void initState() {
    super.initState();
    _buttonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.05,
    );
  }

  @override
  void dispose() {
    _buttonScaleController.dispose();
    capitalController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void _runOptimization() async {
    double capital = _currentCapital;
    int minAssets = int.tryParse(amountController.text) ?? 3;

    if (capital <= 0) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid capital amount')),
      );
      return;
    }

    setState(() => _isCalculating = true);
    await Future.delayed(const Duration(milliseconds: 1500));

    // The backend uses fixed depositAmount on options to perform the search.
    // We generate default split amounts (equal distribution) before passing to backend.
    final available = _optimizerService.allOptions;
    final preparedOptions = _optimizerService.generateDefaultDeposits(
      options: available,
      capacity: capital,
      targetCount: minAssets,
    );

    final result = _optimizerService.solveKnapsack(
      capacity: capital,
      riskPreference: selectedRisk,
      horizon: selectedHorizon,
      minOptions: minAssets,
      customOptions: preparedOptions,
    );

    setState(() => _isCalculating = false);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ResultPage(optimizationResult: result)),
      );
    }
  }

  void _quickSet(double amount) {
    capitalController.text = _currencyFormat.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: Stack(
        children: [
          _buildBackgroundDecor(),
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _isCalculating ? _buildShimmerLoading() : _buildContent(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecor() {
    return Stack(
      children: [
        Positioned(
          top: -30, right: -30,
          child: Container(width: 300, height: 300, decoration: BoxDecoration(color: const Color(0xFF7B1FA2).withValues(alpha: 0.04), shape: BoxShape.circle)),
        ),
        Positioned(
          bottom: 100, left: -100,
          child: Container(width: 250, height: 250, decoration: BoxDecoration(color: const Color(0xFF4A148C).withValues(alpha: 0.02), shape: BoxShape.circle)),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)]),
      ),
      padding: const EdgeInsets.only(top: 70, bottom: 40, left: 24, right: 24),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Investment Solver', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          Text('BACKTRACKING KNAPSACK ENGINE', style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildSummarySection(),
          const SizedBox(height: 24),
          _buildInputCard(),
          const SizedBox(height: 24),
          _buildActionCard(),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TOTAL CAPITAL', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                Text('₱${_currencyFormat.format(_currentCapital)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Icon(Icons.account_balance_wallet_rounded, color: Colors.greenAccent, size: 28),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 40)],
        border: Border.all(color: Colors.grey[100]!),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          _buildInputField(
            label: 'Investment Amount',
            child: TextField(
              controller: capitalController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.deepPurple),
              decoration: const InputDecoration(border: InputBorder.none, prefixText: '₱ '),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 24),
          _buildInputField(
            label: 'Investment Horizon',
            child: DropdownButton<String>(
              value: selectedHorizon, isExpanded: true, underline: const SizedBox(),
              items: ['1 month', '3 months', '6 months', '1 year'].map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
              onChanged: (v) => setState(() => selectedHorizon = v!),
            ),
          ),
          const SizedBox(height: 24),
          _buildInputField(
            label: 'Risk Tolerance',
            child: DropdownButton<String>(
              value: selectedRisk, isExpanded: true, underline: const SizedBox(),
              items: ['Conservative', 'Moderate', 'Aggressive'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => selectedRisk = v!),
            ),
          ),
          const SizedBox(height: 24),
          _buildInputField(
            label: 'Diversification Target (Assets)',
            child: TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontWeight: FontWeight.bold),
              decoration: const InputDecoration(border: InputBorder.none, suffixText: 'Assets'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16)),
          child: child,
        ),
      ],
    );
  }

  Widget _buildActionCard() {
    return SizedBox(
      width: double.infinity, height: 70,
      child: ElevatedButton(
        onPressed: _runOptimization,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A148C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: const Text('SOLVE FOR OPTIMAL PORTFOLIO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildBottomNav(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    double? value = double.tryParse(newValue.text.replaceAll(',', ''));
    if (value == null) return oldValue;
    String formatted = NumberFormat("#,##0", "en_US").format(value);
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}
