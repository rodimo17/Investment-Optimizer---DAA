// High-Fidelity Next-Gen UI Version
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'details.dart';
import 'result.dart';
import '../services/optimizer_service.dart';
import '../services/etf_price_service.dart';

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
  final EtfPriceService _etfService = EtfPriceService();
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "en_US");
  
  List<EtfPriceData> _liveEtfs = [];

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
    
    // Fetch ETF/Bank rates in parallel
    final results = await Future.wait([
      _optimizerService.fetchLatestRates(),
      _etfService.fetchRealTimePrices(),
    ]);
    
    if (mounted) {
      setState(() {
        _isUpdatingRates = false;
        _liveEtfs = results[1] as List<EtfPriceData>;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Live market data synced successfully!', 
            style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2)),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFF1A237E),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              _buildLiveTicker(),
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
          child: Container(width: 300, height: 300, decoration: BoxDecoration(color: const Color(0xFF7B1FA2).withOpacity(0.04), shape: BoxShape.circle)),
        ),
        Positioned(
          top: 200, left: -50,
          child: Container(width: 150, height: 150, decoration: BoxDecoration(color: Colors.blue.withOpacity(0.03), shape: BoxShape.circle)),
        ),
        Positioned(
          bottom: 100, left: -100,
          child: Container(width: 250, height: 250, decoration: BoxDecoration(color: const Color(0xFF4A148C).withOpacity(0.02), shape: BoxShape.circle)),
        ),
      ],
    );
  }

  Widget _buildLiveTicker() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1A237E),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 24),
            if (_liveEtfs.isEmpty)
              const Text('Connecting to live markets...', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold))
            else
              ..._liveEtfs.map((etf) => _TickerItem(
                label: etf.ticker, 
                value: '₱${_currencyFormat.format(etf.currentPricePhp)}', 
                change: '${etf.monthlyChange >= 0 ? '+' : ''}${etf.monthlyChange.toStringAsFixed(2)}%',
                up: etf.monthlyChange >= 0
              )),
            const _TickerItem(label: 'MAYA', value: '10.0% APY', up: true),
            const _TickerItem(label: 'SEABANK', value: '4.25% APY', up: false),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
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
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF1A237E), Color(0xFF311B92)],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 12))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('INVESTMENT TARGET', 
                        style: TextStyle(
                          color: Colors.white60, 
                          fontSize: 10, 
                          fontWeight: FontWeight.w900, 
                          letterSpacing: 2.0,
                        )),
                      const SizedBox(height: 12),
                      Text('₱${_currencyFormat.format(_currentCapital)}', 
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 32, 
                          fontWeight: FontWeight.bold, 
                          letterSpacing: -1.0,
                          height: 1.1,
                        )),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.analytics_rounded, color: Colors.greenAccent, size: 28),
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
        baseColor: Colors.grey[100]!,
        highlightColor: Colors.white,
        child: Column(
          children: [
            Container(height: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32))),
            const SizedBox(height: 24),
            Container(height: 380, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32))),
            const SizedBox(height: 24),
            Container(height: 70, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
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
      ),
      padding: const EdgeInsets.only(top: 70, bottom: 25, left: 24, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Smart Investor', 
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 32, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: -1.5,
                  height: 1.0,
                )),
              SizedBox(height: 6),
              Text('PRECISION OPTIMIZATION', 
                style: TextStyle(
                  color: Colors.white60, 
                  fontSize: 10, 
                  letterSpacing: 2.5, 
                  fontWeight: FontWeight.w800,
                )),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
        child: _isUpdatingRates
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildInputCard() {
    return _EntranceAnimation(
      delay: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 40, offset: const Offset(0, 20))],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.auto_awesome_mosaic_rounded, color: Colors.deepPurple, size: 20)),
                  const SizedBox(width: 14),
                  const Text('Strategy Engine', 
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      fontSize: 18, 
                      color: Color(0xFF1A237E), 
                      letterSpacing: -0.5,
                    )),
                ]),
                const SizedBox(height: 32),
                _buildInputField(
                  label: 'Available Capital',
                  icon: Icons.account_balance_wallet_rounded,
                  child: TextField(
                    controller: capitalController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.deepPurple, letterSpacing: -1.0),
                    decoration: const InputDecoration(
                      hintText: '0', 
                      border: InputBorder.none, 
                      isDense: true, 
                      prefixText: '₱ ', 
                      prefixStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.deepPurple),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
                  child: Row(children: ['10k', '50k', '100k', '500k', '1M'].map((label) => Padding(padding: const EdgeInsets.only(right: 8), child: _buildQuickSetButton(label, double.parse(label.replaceAll('k', '000').replaceAll('M', '1000000'))))).toList()),
                ),
                const SizedBox(height: 32),
                _buildInputField(
                  label: 'Investment Duration',
                  icon: Icons.timer_rounded,
                  child: DropdownButton<String>(
                    value: selectedHorizon, isExpanded: true, underline: const SizedBox(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.deepPurple),
                    items: ['1 month', '3 months', '6 months', '1 year'].map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))).toList(),
                    onChanged: (v) => setState(() => selectedHorizon = v!),
                  ),
                ),
                const SizedBox(height: 28),
                _buildRiskField(),
                const SizedBox(height: 28),
                _buildInputField(
                  label: 'Max Asset Limit',
                  icon: Icons.hub_rounded,
                  child: TextField(
                    controller: amountController, keyboardType: TextInputType.number,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                    decoration: const InputDecoration(
                      hintText: 'Max assets', 
                      border: InputBorder.none, 
                      isDense: true, 
                      suffixText: 'ASSETS', 
                      suffixStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey, letterSpacing: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSetButton(String label, double amount) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.deepPurple, fontSize: 11)),
      backgroundColor: Colors.deepPurple.withOpacity(0.04),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide.none),
      onPressed: () { _quickSet(amount); HapticFeedback.selectionClick(); },
    );
  }

  Widget _buildRiskField() {
    final colors = {'Conservative': Colors.teal, 'Moderate': Colors.orange[700], 'Aggressive': Colors.redAccent[700]};
    final descs = {'Conservative': 'Safe yield & liquidity', 'Moderate': 'Balanced growth path', 'Aggressive': 'Maximized return potential'};
    Color riskColor = colors[selectedRisk] ?? Colors.grey;
    String riskDesc = descs[selectedRisk] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.shield_rounded, size: 16, color: Colors.grey[400]), const SizedBox(width: 8),
          const Text('RISK TOLERANCE', 
            style: TextStyle(
              color: Colors.grey, 
              fontSize: 10, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 1.5,
            )),
          const Spacer(),
          AnimatedContainer(duration: const Duration(milliseconds: 400), width: 12, height: 12, decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: riskColor.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)])),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withOpacity(0.1))),
          child: DropdownButton<String>(
            value: selectedRisk, isExpanded: true, underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.deepPurple),
            items: ['Conservative', 'Moderate', 'Aggressive'].map((r) => DropdownMenuItem(value: r, child: Text(r, style: TextStyle(color: colors[r], fontWeight: FontWeight.w900, fontSize: 16)))).toList(),
            onChanged: (v) => setState(() => selectedRisk = v!),
          ),
        ),
        Padding(padding: const EdgeInsets.only(left: 4, top: 8), child: Text(riskDesc, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, letterSpacing: 0.2))),
      ],
    );
  }

  Widget _buildInputField({required String label, required IconData icon, required Widget child}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 16, color: Colors.grey[400]), 
        const SizedBox(width: 8), 
        Text(label.toUpperCase(), 
          style: const TextStyle(
            color: Colors.grey, 
            fontSize: 10, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 1.5,
          ))
      ]),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withOpacity(0.1))), child: child),
    ]);
  }

  Widget _buildActionCard() {
    return _EntranceAnimation(
      delay: 400,
      child: GestureDetector(
        onTapDown: (_) => _buttonScaleController.forward(), onTapUp: (_) => _buttonScaleController.reverse(), onTapCancel: () => _buttonScaleController.reverse(),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.94).animate(CurvedAnimation(parent: _buttonScaleController, curve: Curves.easeInOut)),
          child: Container(
            width: double.infinity, height: 75,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF311B92), Color(0xFF6A1B9A)], begin: Alignment.centerLeft, end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.4), blurRadius: 25, offset: const Offset(0, 12))],
            ),
            child: ElevatedButton(
              onPressed: () { HapticFeedback.heavyImpact(); _runOptimization(); },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: Colors.white, shadowColor: Colors.transparent, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.bolt_rounded, color: Colors.amber, size: 30), SizedBox(width: 12), Text('OPTIMIZE PORTFOLIO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: 2))]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
      height: 85,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117), 
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(3, (i) => _buildNavItem([Icons.auto_graph_rounded, Icons.home_filled, Icons.info_rounded][i], i))),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isActive = index == 1;
    return GestureDetector(
      onTap: () { if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (context) => const DetailsPage())); HapticFeedback.selectionClick(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500), curve: Curves.elasticOut,
        padding: EdgeInsets.all(isActive ? 18 : 14),
        decoration: BoxDecoration(color: isActive ? Colors.white.withOpacity(0.12) : Colors.transparent, borderRadius: BorderRadius.circular(24)),
        child: Icon(icon, color: isActive ? Colors.white : Colors.white38, size: isActive ? 30 : 26),
      ),
    );
  }
}

class _TickerItem extends StatelessWidget {
  final String label;
  final String value;
  final String? change;
  final bool up;
  const _TickerItem({required this.label, required this.value, this.change, required this.up});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 32),
      child: Row(
        children: [
          Text(label, 
            style: const TextStyle(
              color: Colors.white54, 
              fontSize: 10, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 1.2,
            )),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          if (change != null)
            Text(change!, style: TextStyle(color: up ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w600)),
          Icon(up ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: up ? Colors.greenAccent : Colors.redAccent, size: 16),
        ],
      ),
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
      duration: const Duration(milliseconds: 1200),
      curve: Interval(delay / 2500, 1.0, curve: Curves.easeOutQuart),
      builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 40 * (1 - value)), child: child)),
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
