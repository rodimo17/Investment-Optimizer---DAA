import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'details.dart';
import 'result.dart';
import 'settings.dart';
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
  final _settings = AppSettings();

  late String _selectedHorizon;
  late String _selectedRisk;

  int _minOptions = 1;
  int _maxOptions = 9;

  bool _isUpdatingRates = false;
  bool _isCalculating = false;

  final OptimizerService _optimizerService = OptimizerService();
  late NumberFormat _currencyFormat;

  late Map<String, TextEditingController> _depositControllers;

  // ── Currency helpers ──────────────────────────────────────────────────────

  /// Returns the currency symbol from the settings string, e.g. '₱ PHP' → '₱'
  String get _currencySymbol => _settings.currency.split(' ').first;

  /// Rebuilds the NumberFormat whenever decimal places change.
  void _rebuildCurrencyFormat() {
    final decimals = _settings.decimalPlaces;
    final pattern = decimals == 0
        ? '#,##0'
        : '#,##0.${'0' * decimals}';
    _currencyFormat = NumberFormat(pattern, 'en_US');
  }

  @override
  void initState() {
    super.initState();

    // Pick up defaults from settings
    _selectedHorizon = _settings.defaultHorizon;
    _selectedRisk = _settings.defaultRisk;

    _rebuildCurrencyFormat();

    _maxOptions = _optimizerService.allOptions.length;
    _depositControllers = {
      for (final opt in _optimizerService.allOptions)
        opt.name: TextEditingController(
          text: opt.depositAmount > 0
              ? _currencyFormat.format(opt.depositAmount).split('.')[0]
              : '',
        ),
    };

    // Listen to settings changes so currency / decimal updates are reactive
    _settings.addListener(_onSettingsChanged);

    // Auto-refresh rates if the user enabled that option
    if (_settings.autoRefreshRates) {
      _fetchRates();
    }
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {
        _rebuildCurrencyFormat();
      });
    }
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _capitalController.dispose();
    for (final c in _depositControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _formatController(TextEditingController controller) {
    String text = controller.text.replaceAll(',', '');
    if (text.isEmpty) return;
    if (text == '.') return;

    // Handle multiple dots
    if ('.'.allMatches(text).length > 1) {
      text = text.substring(0, text.lastIndexOf('.'));
    }
    final value = double.tryParse(text);
    if (value != null) {
      String formatted;
      if (text.contains('.')) {
        List<String> parts = text.split('.');
        String whole = _currencyFormat
            .format(double.parse(parts[0] == '' ? '0' : parts[0]))
            .split('.')[0];
        String decimal = parts[1];
        if (decimal.length > 2) decimal = decimal.substring(0, 2);
        formatted = '$whole.$decimal';
      } else {
        formatted = _currencyFormat.format(value).split('.')[0];
      }

      if (controller.text == formatted) return;

      int selectionOffset = controller.selection.baseOffset;
      int oldLength = controller.text.length;

      controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(
          offset: (selectionOffset + (formatted.length - oldLength))
              .clamp(0, formatted.length),
        ),
      );
    }
  }

  void _fetchRates() async {
    setState(() => _isUpdatingRates = true);
    final etfPriceService = EtfPriceService();
    final results = await etfPriceService.getMonthlyPrices();
    _optimizerService.updateEtfRates(results);
    if (mounted) {
      setState(() => _isUpdatingRates = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rates refreshed and synced with Optimizer.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddOptionDialog() {
    final nameController = TextEditingController();
    final rateController = TextEditingController();
    final minInvestController = TextEditingController();
    InvestmentType selectedType = InvestmentType.bank;
    int selectedRiskScore = 1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Add Custom Option',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogField('Asset Name', nameController, 'e.g. GSave',
                    Icons.label_outline),
                const SizedBox(height: 16),
                _dialogField('Annual Rate', rateController, 'e.g. 0.05 for 5%',
                    Icons.percent,
                    isNumber: true),
                const SizedBox(height: 16),
                _dialogField('Min Investment', minInvestController, '0',
                    Icons.payments_outlined,
                    isNumber: true),
                const SizedBox(height: 24),
                const Text('Category',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: _typeChoice(InvestmentType.bank, selectedType,
                            (v) => setDialogState(() => selectedType = v))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _typeChoice(InvestmentType.etf, selectedType,
                            (v) => setDialogState(() => selectedType = v))),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Risk Score',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                    Text('$selectedRiskScore/10',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo)),
                  ],
                ),
                Slider(
                  value: selectedRiskScore.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: Colors.indigo,
                  onChanged: (v) =>
                      setDialogState(() => selectedRiskScore = v.toInt()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final rate = double.tryParse(rateController.text) ?? 0.0;
              final min = double.tryParse(
                      minInvestController.text.replaceAll(',', '')) ??
                  0.0;
              if (name.isEmpty) return;

              final newOpt = InvestmentOption(
                name: name,
                annualReturnRate: rate,
                type: selectedType,
                riskLevel: selectedRiskScore <= 3
                    ? 'Conservative'
                    : (selectedRiskScore <= 7 ? 'Moderate' : 'Aggressive'),
                riskScore: selectedRiskScore,
                minInvestment: min,
                depositAmount: 0,
              );

              _optimizerService.addCustomOption(newOpt);
              _depositControllers[name] = TextEditingController();

              setState(() {
                _maxOptions = _optimizerService.allOptions.length;
              });
              Navigator.pop(context);
            },
            child: const Text('ADD ASSET'),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController controller,
      String hint, IconData icon,
      {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              icon: Icon(icon, size: 18, color: Colors.grey),
            ),
            onChanged: isNumber && label == 'Min Investment'
                ? (_) => _formatController(controller)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _typeChoice(InvestmentType type, InvestmentType selected,
      Function(InvestmentType) onSelect) {
    final isSelected = type == selected;
    return InkWell(
      onTap: () => onSelect(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: isSelected ? Colors.indigo : Colors.grey[300]!),
        ),
        child: Text(
          type.name.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  List<InvestmentOption>? _buildOptionsWithDeposits(double capital) {
    final options = <InvestmentOption>[];
    for (final opt in _optimizerService.allOptions) {
      final raw =
          _depositControllers[opt.name]!.text.replaceAll(',', '').trim();
      if (raw.isEmpty) continue;
      final amount = double.tryParse(raw);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Invalid deposit amount for ${opt.name}.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
        return null;
      }
      if (amount < opt.minInvestment) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            '${opt.name} requires a minimum of '
            '$_currencySymbol${_currencyFormat.format(opt.minInvestment)}.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
        return null;
      }
      options.add(InvestmentOption(
        name: opt.name,
        annualReturnRate: opt.annualReturnRate,
        type: opt.type,
        riskLevel: opt.riskLevel,
        riskScore: opt.riskScore,
        minInvestment: opt.minInvestment,
        depositAmount: amount,
      ));
    }
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter at least one deposit amount to continue.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return null;
    }
    final total = options.fold<double>(0, (sum, o) => sum + o.depositAmount);
    if (total > capital) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Total deposits ($_currencySymbol${_currencyFormat.format(total)}) '
          'exceed your capital. '
          'The optimizer will find the best subset that fits.',
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ));
    }
    return options;
  }

  void _runOptimization() async {
    final raw = _capitalController.text.replaceAll(',', '');
    final capital = double.tryParse(raw) ?? 0.0;
    if (capital <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a valid capital amount.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final options = _buildOptionsWithDeposits(capital);
    if (options == null) return;
    final effectiveMin = _minOptions.clamp(1, options.length);
    final effectiveMax = _maxOptions.clamp(effectiveMin, options.length);
    setState(() => _isCalculating = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    final result = _optimizerService.solveKnapsack(
      capacity: capital,
      riskPreference: _selectedRisk,
      horizon: _selectedHorizon,
      minOptions: effectiveMin,
      maxOptions: effectiveMax,
      customOptions: options,
    );
    setState(() => _isCalculating = false);
    if (mounted) {
      // ── Animate Results setting ──────────────────────────────────────────
      // When animateResults is enabled, use a fade transition; otherwise push
      // with the default platform transition.
      if (_settings.animateResults) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) =>
                ResultPage(optimizationResult: result),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultPage(optimizationResult: result),
          ),
        );
      }
    }
  }

  void _quickSet(double amount) {
    final formatted = _currencyFormat.format(amount).split('.')[0];
    _capitalController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    setState(() {});
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Rebuild whenever AppSettings notifies (already handled via listener,
    // but wrapping in ListenableBuilder ensures the entire tree re-renders).
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          bottomNavigationBar: _buildBottomNav(),
          body: Column(
            children: [
              _buildHeader(),
              Expanded(
                child:
                    _isCalculating ? _buildShimmerLoading() : _buildContent(),
              ),
            ],
          ),
        );
      },
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
          _buildOptionsRangeCard(),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.indigo[900]!, Colors.deepPurple[800]!],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding:
          const EdgeInsets.only(top: 60, bottom: 40, left: 24, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Investi-Aid',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _isUpdatingRates
                  ? const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3),
                      ),
                    )
                  : _headerIconButton(
                      Icons.refresh_rounded, 'Sync Market Data', _fetchRates),
              const SizedBox(width: 8),
              _headerIconButton(
                Icons.settings_outlined,
                'Settings',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton(
      IconData icon, String tooltip, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        tooltip: tooltip,
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Color(0xFF1E293B)),
              decoration: InputDecoration(
                hintText: '0',
                border: InputBorder.none,
                isDense: true,
                // ── Display Currency setting ───────────────────────────────
                prefixText: '$_currencySymbol ',
                prefixStyle: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                    fontSize: 24),
              ),
              onChanged: (_) {
                _formatController(_capitalController);
                setState(() {});
              },
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
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant),
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
              dropdownColor: Theme.of(context).cardColor,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
              ),
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
      'Conservative': const Color(0xFF059669),
      'Moderate': Colors.amber[700]!,
      'Aggressive': const Color(0xFFE11D48),
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
            // ── Show Risk Badge setting ──────────────────────────────────
            if (_settings.showRiskBadge)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'MAX RISK: $maxRisk',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
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
            dropdownColor: Theme.of(context).cardColor,
            icon: const Icon(Icons.expand_more_rounded,
                color: Color(0xFF94A3B8)),
            items: ['Conservative', 'Moderate', 'Aggressive']
                .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(
                        r,
                        style: TextStyle(
                          color: colors[r],
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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

  // ── Min / Max options card ────────────────────────────────────────────────

  Widget _buildOptionsRangeCard() {
    final total = _optimizerService.allOptions.length;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.format_list_numbered_outlined, 'Portfolio Size'),
          const SizedBox(height: 4),
          Text(
            'Set how many assets the optimizer must include at minimum, '
            'and the maximum it may pick.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          _fieldLabel(Icons.arrow_downward, 'Minimum assets'),
          const SizedBox(height: 8),
          _stepperRow(
            value: _minOptions,
            min: 1,
            max: _maxOptions,
            onDecrement: () => setState(() => _minOptions--),
            onIncrement: () => setState(() {
              _minOptions++;
              if (_minOptions > _maxOptions) _maxOptions = _minOptions;
            }),
          ),
          const SizedBox(height: 20),
          _fieldLabel(Icons.arrow_upward, 'Maximum assets'),
          const SizedBox(height: 8),
          _stepperRow(
            value: _maxOptions,
            min: _minOptions,
            max: total,
            onDecrement: () => setState(() {
              _maxOptions--;
              if (_maxOptions < _minOptions) _minOptions = _maxOptions;
            }),
            onIncrement: () => setState(() => _maxOptions++),
          ),
        ],
      ),
    );
  }

  Widget _stepperRow({
    required int value,
    required int min,
    required int max,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return _fieldBox(
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: value > min ? onDecrement : null,
            color: Colors.deepPurple,
            iconSize: 20,
          ),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: value < max ? onIncrement : null,
            color: Colors.deepPurple,
            iconSize: 20,
          ),
        ],
      ),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'How much do you want to commit to each option?',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.indigo[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add_rounded,
                      color: Colors.indigo, size: 20),
                  onPressed: _showAddOptionDialog,
                  tooltip: 'Add Custom Option',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
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
    final isBuiltIn = [
      'Maya Bank',
      'SeaBank',
      'UNO Digital',
      'GoTyme Bank',
      'Tonik Bank',
      'CIMB Bank',
      'VOO ETF',
      'VTI ETF',
      'QQQ ETF',
    ].contains(opt.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onLongPress: isBuiltIn
                ? null
                : () => setState(() {
                      _optimizerService.removeCustomOption(opt.name);
                      _depositControllers.remove(opt.name)?.dispose();
                      _maxOptions = _optimizerService.allOptions.length;
                      if (_minOptions > _maxOptions)
                        _minOptions = _maxOptions;
                    }),
            child: Container(
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
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opt.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  // ── Decimal Places + Display Currency settings ───────────
                  '${(opt.annualReturnRate * 100).toStringAsFixed(_settings.decimalPlaces)}% p.a. · '
                  'min $_currencySymbol${_currencyFormat.format(opt.minInvestment)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFE2E8F0), width: 1.5),
              ),
              child: TextField(
                controller: _depositControllers[opt.name],
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  // ── Display Currency setting ───────────────────────────
                  prefixText: _currencySymbol,
                  prefixStyle: const TextStyle(
                      color: Color(0xFF94A3B8), fontSize: 12),
                  hintText: '0',
                  hintStyle:
                      const TextStyle(color: Color(0xFFCBD5E1)),
                ),
                onChanged: (_) {
                  _formatController(_depositControllers[opt.name]!);
                  setState(() {});
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Run button ────────────────────────────────────────────────────────────

  Widget _buildRunButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[800]!, Colors.indigo[600]!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _runOptimization,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt_rounded, size: 22),
            SizedBox(width: 12),
            Text(
              'RUN BACKTRACKING SOLVER',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shimmer ───────────────────────────────────────────────────────────────

  Widget _buildShimmerLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        child: Column(
          children: [
            _shimmerBlock(160),
            const SizedBox(height: 16),
            _shimmerBlock(160),
            const SizedBox(height: 16),
            _shimmerBlock(300),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBlock(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  // ── Bottom nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08), blurRadius: 10),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor:
            Theme.of(context).colorScheme.onSurfaceVariant,
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 24,
            offset: const Offset(0, 10),
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.indigo[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.indigo[700], size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _fieldBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: child,
    );
  }

  Widget _fieldLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon,
            size: 15,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 1.2,
      ),
    );
  }
}