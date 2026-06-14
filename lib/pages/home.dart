import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final TextEditingController capitalController = TextEditingController();
  final TextEditingController amountController = TextEditingController(text: '2'); 
  String selectedHorizon = '1 month';
  String selectedRisk = 'Moderate';
  bool _isUpdatingRates = false;
  bool _isCalculating = false;

  late AnimationController _buttonScaleController;
  final OptimizerService _optimizerService = OptimizerService();
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "en_US");

  double get _currentCapital => double.tryParse(capitalController.text.replaceAll(',', '')) ?? 0.0;

  @override
  void initState() {
    super.initState();
    _fetchRates();
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

  Future<void> _fetchRates() async {
    setState(() => _isUpdatingRates = true);
    await _optimizerService.fetchLatestRates();
    if (mounted) {
      setState(() => _isUpdatingRates = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bank interest rates updated!', style: TextStyle(fontWeight: FontWeight.w500)),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.deepPurple[700],
        ),
      );
    }
  }

  void _runOptimization() async {
    double capital = _currentCapital;
    int maxOptions = int.tryParse(amountController.text) ?? 2;

    if (capital <= 0) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid capital amount'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent[700],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isCalculating = true);
    await Future.delayed(const Duration(milliseconds: 1500));

    final result = _optimizerService.solveKnapsack(
      capacity: capital,
      riskPreference: selectedRisk,
      horizon: selectedHorizon,
      maxOptions: maxOptions,
    );

    setState(() => _isCalculating = false);

    if (mounted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ResultPage(optimizationResult: result),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
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
      bottomNavigationBar: _buildBottomNav(),
      body: Stack(
        children: [
          _buildBackgroundDecor(),
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
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
          top: -50, right: -50,
          child: Container(width: 250, height: 250, decoration: BoxDecoration(color: const Color(0xFF7B1FA2).withOpacity(0.04), shape: BoxShape.circle)),
        ),
        Positioned(
          bottom: 150, left: -80,
          child: Container(width: 200, height: 200, decoration: BoxDecoration(color: const Color(0xFF4A148C).withOpacity(0.02), shape: BoxShape.circle)),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
    return ValueListenableBuilder(
      valueListenable: capitalController,
      builder: (context, value, child) {
        return _EntranceAnimation(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.deepPurple[900],
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('INVESTMENT TARGET', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      Text('₱${_currencyFormat.format(_currentCapital)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: const Column(
                    children: [
                      Icon(Icons.trending_up, color: Colors.greenAccent, size: 20),
                      SizedBox(height: 4),
                      Text('12.5%', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.white,
        child: Column(
          children: [
            Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28))),
            const SizedBox(height: 24),
            Container(height: 350, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28))),
            const SizedBox(height: 24),
            Container(height: 65, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4A148C), Color(0xFF6A1B9A), Color(0xFF7B1FA2)]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(45), bottomRight: Radius.circular(45)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))],
      ),
      padding: const EdgeInsets.only(top: 70, bottom: 45, left: 24, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Smart Investor', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1)),
              const SizedBox(height: 4),
              Text('BACKTRACKING SOLVER', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w800)),
            ],
          ),
          _buildRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return GestureDetector(
      onTap: _isUpdatingRates ? null : _fetchRates,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
        child: _isUpdatingRates
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildInputCard() {
    return _EntranceAnimation(
      delay: 200,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 30, offset: const Offset(0, 15))],
          border: Border.all(color: Colors.grey[100]!, width: 1),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.tune_rounded, color: Colors.deepPurple, size: 20)),
              const SizedBox(width: 14),
              const Text('Strategy Configuration', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1A237E), letterSpacing: -0.5)),
            ]),
            const SizedBox(height: 28),
            _buildInputField(
              label: 'Investment Capital',
              icon: Icons.account_balance_wallet_rounded,
              child: TextField(
                controller: capitalController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.deepPurple, letterSpacing: -0.5),
                decoration: const InputDecoration(hintText: '0', border: InputBorder.none, isDense: true, prefixText: '₱ ', prefixStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.deepPurple)),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
              child: Row(children: ['10k', '50k', '100k', '500k'].map((label) => Padding(padding: const EdgeInsets.only(right: 8), child: _buildQuickSetButton(label, double.parse(label.replaceAll('k', '000'))))).toList()),
            ),
            const SizedBox(height: 32),
            _buildInputField(
              label: 'Investment Duration',
              icon: Icons.timer_rounded,
              child: DropdownButton<String>(
                value: selectedHorizon, isExpanded: true, underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.deepPurple),
                items: ['1 month', '3 months', '6 months', '1 year'].map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)))).toList(),
                onChanged: (v) => setState(() => selectedHorizon = v!),
              ),
            ),
            const SizedBox(height: 24),
            _buildRiskField(),
            const SizedBox(height: 24),
            _buildInputField(
              label: 'Portfolio Diversification',
              icon: Icons.hub_rounded,
              child: TextField(
                controller: amountController, keyboardType: TextInputType.number,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                decoration: const InputDecoration(hintText: 'Max assets', border: InputBorder.none, isDense: true, suffixText: 'ASSETS', suffixStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSetButton(String label, double amount) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.deepPurple, fontSize: 12)),
      backgroundColor: Colors.deepPurple.withOpacity(0.05),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
      onPressed: () { _quickSet(amount); HapticFeedback.lightImpact(); },
    );
  }

  Widget _buildRiskField() {
    final colors = {'Conservative': Colors.teal, 'Moderate': Colors.orange[700], 'Aggressive': Colors.redAccent[700]};
    final descs = {'Conservative': 'Prioritize safety and stability', 'Moderate': 'Balanced risk and market returns', 'Aggressive': 'High risk for potential high growth'};
    Color riskColor = colors[selectedRisk] ?? Colors.grey;
    String riskDesc = descs[selectedRisk] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.shield_rounded, size: 16, color: Colors.grey[400]), const SizedBox(width: 8),
          const Text('RISK TOLERANCE', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const Spacer(),
          AnimatedContainer(duration: const Duration(milliseconds: 300), width: 10, height: 10, decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: riskColor.withOpacity(0.3), blurRadius: 6, spreadRadius: 1)])),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey[200]!)),
          child: DropdownButton<String>(
            value: selectedRisk, isExpanded: true, underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.deepPurple),
            items: ['Conservative', 'Moderate', 'Aggressive'].map((r) => DropdownMenuItem(value: r, child: Text(r, style: TextStyle(color: colors[r], fontWeight: FontWeight.bold, fontSize: 15)))).toList(),
            onChanged: (v) => setState(() => selectedRisk = v!),
          ),
        ),
        Padding(padding: const EdgeInsets.only(left: 4, top: 6), child: Text(riskDesc, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildInputField({required String label, required IconData icon, required Widget child}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 16, color: Colors.grey[400]), const SizedBox(width: 8), Text(label.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1))]),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey[200]!)), child: child),
    ]);
  }

  Widget _buildActionCard() {
    return _EntranceAnimation(
      delay: 400,
      child: GestureDetector(
        onTapDown: (_) => _buttonScaleController.forward(), onTapUp: (_) => _buttonScaleController.reverse(), onTapCancel: () => _buttonScaleController.reverse(),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.95).animate(_buttonScaleController),
          child: SizedBox(
            width: double.infinity, height: 70,
            child: ElevatedButton(
              onPressed: () { HapticFeedback.mediumImpact(); _runOptimization(); },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: Colors.white, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), elevation: 0),
              child: Ink(
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)], begin: Alignment.centerLeft, end: Alignment.centerRight), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))]),
                child: Container(alignment: Alignment.center, child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.bolt_rounded, color: Colors.amber, size: 28), SizedBox(width: 12), Text('OPTIMIZE PORTFOLIO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5))])),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 35),
      height: 80,
      decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(35), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 15))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(3, (i) => _buildNavItem([Icons.analytics_rounded, Icons.home_rounded, Icons.info_rounded][i], i))),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isActive = index == 1;
    return GestureDetector(
      onTap: () { if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (context) => const DetailsPage())); HapticFeedback.selectionClick(); },
      child: AnimatedContainer(duration: const Duration(milliseconds: 400), curve: Curves.elasticOut, padding: EdgeInsets.all(isActive ? 16 : 12), decoration: BoxDecoration(color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(20)), child: Icon(icon, color: isActive ? Colors.white : Colors.white54, size: isActive ? 28 : 24)),
    );
  }
}

class _EntranceAnimation extends StatelessWidget {
  final Widget child;
  final int delay;
  const _EntranceAnimation({required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Interval(delay / 2000, 1.0, curve: Curves.easeOutCubic),
      builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 30 * (1 - value)), child: child)),
      child: child,
    );
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
