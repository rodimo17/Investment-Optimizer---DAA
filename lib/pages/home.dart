import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'details.dart';
import 'result.dart';
import '../models/investment_option.dart';
import '../services/optimizer_service.dart';
import '../services/etf_price_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _capitalController = TextEditingController();
  String _selectedHorizon = '1 month';
  String _selectedRisk = 'Moderate';
  bool _isUpdatingRates = false;
  bool _isCalculating = false;

  final OptimizerService _optimizerService = OptimizerService();
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "en_US");

  // One controller per option, keyed by option name
  late Map<String, TextEditingController> _depositControllers;

  @override
  void initState() {
    super.initState();

    // Pre-populate deposit controllers from each option's default depositAmount
    _depositControllers = {
      for (final opt in _optimizerService.allOptions)
        opt.name: TextEditingController(
          text: opt.depositAmount > 0
              ? _currencyFormat.format(opt.depositAmount)
              : '',
        ),
    };

    _capitalController.addListener(_formatCapital);
    _fetchRates();
  }

  @override
  void dispose() {
    _capitalController.removeListener(_formatCapital);
    _capitalController.dispose();
    for (final c in _depositControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _formatCapital() {
    final raw = _capitalController.text.replaceAll(',', '');
    if (raw.isEmpty) return;
    _capitalController.removeListener(_formatCapital);
    final value = double.tryParse(raw);
    if (value != null) {
      final formatted = _currencyFormat.format(value);
      _capitalController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    _capitalController.addListener(_formatCapital);
  }

  Future<void> _fetchRates() async {
    setState(() => _isUpdatingRates = true);
    final _etfPriceService = EtfPriceService();
    await _etfPriceService.getMonthlyPrices();
    if (mounted) {
      setState(() => _isUpdatingRates = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rates refreshed.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Builds the list of InvestmentOptions with user-supplied deposit amounts
  /// injected. Returns null with a snackbar if any input is invalid.
  List<InvestmentOption>? _buildOptionsWithDeposits(double capital) {
    final options = <InvestmentOption>[];

    for (final opt in _optimizerService.allOptions) {
      final raw = _depositControllers[opt.name]!.text.replaceAll(',', '').trim();

      // Empty means the user doesn't want to include this option at all —
      // skip it rather than error.
      if (raw.isEmpty) continue;

      final amount = double.tryParse(raw);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid deposit amount for ${opt.name}.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return null;
      }

      if (amount < opt.minInvestment) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${opt.name} requires a minimum of ₱${_currencyFormat.format(opt.minInvestment)}.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return null;
      }

      options.add(InvestmentOption(
        name: opt.name,
        annualReturnRate: opt.annualReturnRate,
        type: opt.type,
        riskLevel: opt.riskLevel,
        riskScore: opt.riskScore,
        minInvestment: opt.minInvestment,
        depositAmount: amount.toInt(), //to be fixed kasi di ko mahanap san yung amount
      ));
    }

    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter at least one deposit amount to continue.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }

    // Warn if total deposits exceed capital — optimizer will prune but user
    // should know.
    final total = options.fold<double>(0, (sum, o) => sum + o.depositAmount);
    if (total > capital) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Total deposits (₱${_currencyFormat.format(total)}) exceed your capital. '
            'The optimizer will find the best subset that fits.',
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    return options;
  }

  void _runOptimization() async {
    final raw = _capitalController.text.replaceAll(',', '');
    final capital = double.tryParse(raw) ?? 0.0;

    if (capital <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid capital amount.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final options = _buildOptionsWithDeposits(capital);
    if (options == null) return;

    setState(() => _isCalculating = true);
    await Future.delayed(const Duration(milliseconds: 1200));

    final result = _optimizerService.solveKnapsack(
      capacity: capital,
      riskPreference: _selectedRisk,
      horizon: _selectedHorizon,
      customOptions: options,
    );

    setState(() => _isCalculating = false);

    if (mounted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, __) =>
              ResultPage(optimizationResult: result),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }

  void _quickSet(double amount) {
    final formatted = _currencyFormat.format(amount.toInt());
    _capitalController.removeListener(_formatCapital);
    _capitalController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _capitalController.addListener(_formatCapital);
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
          _buildCapitalCard(),
          const SizedBox(height: 16),
          _buildHorizonRiskCard(),
          const SizedBox(height: 16),
          _buildDepositSlotsCard(),
          const SizedBox(height: 24),
          _buildRunButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.only(top: 60, bottom: 32, left: 24, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Investment Optimizer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'DAA Project · Backtracking Knapsack',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
          _isUpdatingRates
              ? const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: _fetchRates,
                  tooltip: 'Refresh rates',
                ),
        ],
      ),
    );
  }

  // ── Capital card ──────────────────────────────────────────────────────────

  Widget _buildCapitalCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.account_balance_wallet_outlined, 'Total Capital'),
          const SizedBox(height: 16),
          _fieldBox(
            child: TextField(
              controller: _capitalController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              decoration: const InputDecoration(
                hintText: '0',
                border: InputBorder.none,
                isDense: true,
                prefixText: '₱ ',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _quickChip('10k', 10000),
              const SizedBox(width: 8),
              _quickChip('50k', 50000),
              const SizedBox(width: 8),
              _quickChip('100k', 100000),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickChip(String label, double amount) {
    return ActionChip(
      label: Text(label),
      backgroundColor: Colors.grey[100],
      onPressed: () => _quickSet(amount),
    );
  }

  // ── Horizon + Risk card ───────────────────────────────────────────────────

  Widget _buildHorizonRiskCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.tune, 'Strategy'),
          const SizedBox(height: 20),
          _fieldLabel(Icons.calendar_today_outlined, 'Time Horizon'),
          const SizedBox(height: 8),
          _fieldBox(
            child: DropdownButton<String>(
              value: _selectedHorizon,
              isExpanded: true,
              underline: const SizedBox(),
              items: ['1 month', '3 months', '6 months', '1 year']
                  .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedHorizon = v!),
            ),
          ),
          const SizedBox(height: 20),
          _buildRiskSelector(),
        ],
      ),
    );
  }

  Widget _buildRiskSelector() {
    final colors = {
      'Conservative': Colors.green,
      'Moderate': Colors.orange,
      'Aggressive': Colors.red,
    };
    final color = colors[_selectedRisk]!;
    final maxRisk = OptimizerService.riskLimits[_selectedRisk] ?? 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _fieldLabel(Icons.shield_outlined, 'Risk Tolerance'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Max risk score: $maxRisk',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _fieldBox(
          child: DropdownButton<String>(
            value: _selectedRisk,
            isExpanded: true,
            underline: const SizedBox(),
            items: ['Conservative', 'Moderate', 'Aggressive']
                .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(
                        r,
                        style: TextStyle(
                          color: colors[r],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedRisk = v!),
          ),
        ),
      ],
    );
  }

  // ── Deposit slots card ────────────────────────────────────────────────────

  Widget _buildDepositSlotsCard() {
    final banks = _optimizerService.allOptions
        .where((o) => o.type == InvestmentType.bank)
        .toList();
    final etfs = _optimizerService.allOptions
        .where((o) => o.type == InvestmentType.etf)
        .toList();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.savings_outlined, 'Deposit Slots'),
          const SizedBox(height: 4),
          Text(
            'Set how much you want to commit to each option. '
            'Leave blank to exclude it from the search.',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 20),
          _sectionLabel('BANK ACCOUNTS'),
          const SizedBox(height: 12),
          ...banks.map((opt) => _depositRow(opt)),
          const SizedBox(height: 20),
          _sectionLabel('ETF'),
          const SizedBox(height: 12),
          ...etfs.map((opt) => _depositRow(opt)),
        ],
      ),
    );
  }

  Widget _depositRow(InvestmentOption opt) {
    final isEtf = opt.type == InvestmentType.etf;
    final accentColor = isEtf ? Colors.indigo : Colors.deepPurple;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon + name
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isEtf ? Icons.insights : Icons.account_balance,
              size: 18,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opt.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${(opt.annualReturnRate * 100).toStringAsFixed(2)}% p.a. · '
                  'min ₱${_currencyFormat.format(opt.minInvestment)}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Deposit input
          SizedBox(
            width: 110,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                controller: _depositControllers[opt.name],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  prefixText: '₱',
                  hintText: '—',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Run button ────────────────────────────────────────────────────────────

  Widget _buildRunButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _runOptimization,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
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

  // ── Shimmer ───────────────────────────────────────────────────────────────

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DetailsPage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined), label: 'Analysis'),
          BottomNavigationBarItem(
              icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.info_outline), label: 'Details'),
        ],
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }

  Widget _cardTitle(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ],
    );
  }

  Widget _fieldBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: child,
    );
  }

  Widget _fieldLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey[400],
        letterSpacing: 1.2,
      ),
    );
  }
}