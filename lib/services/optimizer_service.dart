import '../models/investment_option.dart';

enum StepType { evaluated, pruned, bestFound, backtrackInfo }

class TraceStep {
  final StepType type;
  final String title;
  final String description;
  final double? profit;

  TraceStep({
    required this.type,
    required this.title,
    required this.description,
    this.profit,
  });
}

class Allocation {
  final InvestmentOption option;
  final double amount;
  final double profit;
  final int rank;

  Allocation({
    required this.option,
    required this.amount,
    required this.profit,
    required this.rank,
  });
}

class OptimizationResult {
  final List<Allocation> allocations;
  final double totalProfit;
  final List<TraceStep> steps;
  final int statesExplored;
  final double totalRiskScore;
  final int maxRiskLimit;
  final double etfAllocationPercent;
  final double bankAllocationPercent;
  final double usedCapital;

  OptimizationResult({
    required this.allocations,
    required this.totalProfit,
    required this.steps,
    required this.statesExplored,
    required this.totalRiskScore,
    required this.maxRiskLimit,
    required this.etfAllocationPercent,
    required this.bankAllocationPercent,
    required this.usedCapital,
  });
}

class _CategoryAllocationResult {
  final bool valid;
  final double usedBudget;
  final double totalProfit;
  final List<Allocation> allocations;

  _CategoryAllocationResult({
    required this.valid,
    required this.usedBudget,
    required this.totalProfit,
    required this.allocations,
  });
}

class _TempAllocation {
  final InvestmentOption option;
  double amount;

  _TempAllocation({required this.option, required this.amount});
}

class OptimizerService {
  static const Map<String, int> riskLimits = {
    'Conservative': 3,
    'Moderate': 6,
    'Aggressive': 10,
  };

  Future<void> fetchLatestRates() async {
  await Future.delayed(const Duration(milliseconds: 1000));
}

  final List<InvestmentOption> allOptions = [
    InvestmentOption(
      name: 'Maya Bank',
      annualReturnRate: 0.10,
      type: InvestmentType.bank,
      riskLevel: 'Conservative',
      riskScore: 1,
      minInvestment: 100,
    ),
    InvestmentOption(
      name: 'SeaBank',
      annualReturnRate: 0.0425,
      type: InvestmentType.bank,
      riskLevel: 'Conservative',
      riskScore: 1,
      minInvestment: 1,
    ),
    InvestmentOption(
      name: 'UNO Digital',
      annualReturnRate: 0.0425,
      type: InvestmentType.bank,
      riskLevel: 'Conservative',
      riskScore: 1,
      minInvestment: 1,
    ),
    InvestmentOption(
      name: 'GoTyme Bank',
      annualReturnRate: 0.04,
      type: InvestmentType.bank,
      riskLevel: 'Conservative',
      riskScore: 1,
      minInvestment: 500,
    ),
    InvestmentOption(
      name: 'Tonik Bank',
      annualReturnRate: 0.04,
      type: InvestmentType.bank,
      riskLevel: 'Conservative',
      riskScore: 1,
      minInvestment: 500,
    ),
    InvestmentOption(
      name: 'CIMB Bank',
      annualReturnRate: 0.025,
      type: InvestmentType.bank,
      riskLevel: 'Conservative',
      riskScore: 1,
      minInvestment: 50,
    ),
    InvestmentOption(
      name: 'VOO ETF',
      annualReturnRate: 0.125,
      type: InvestmentType.etf,
      riskLevel: 'Moderate',
      riskScore: 5,
      minInvestment: 2500,
    ),
    InvestmentOption(
      name: 'VTI ETF',
      annualReturnRate: 0.12,
      type: InvestmentType.etf,
      riskLevel: 'Moderate',
      riskScore: 2,
      minInvestment: 2500,
    ),
    InvestmentOption(
      name: 'QQQ ETF',
      annualReturnRate: 0.18,
      type: InvestmentType.etf,
      riskLevel: 'Aggressive',
      riskScore: 8,
      minInvestment: 5000,
    ),
  ];

  double _maxProfit = -1.0;
  List<Allocation> _bestAllocations = [];
  List<TraceStep> _steps = [];
  int _statesCount = 0;
  double _bestUsedCapital = 0;
  double _bestEtfPercent = 0;
  double _bestBankPercent = 0;
  int _bestRiskScore = 0;

  OptimizationResult solveKnapsack({
    required double capacity,
    required String riskPreference,
    required String horizon,
    required double etfAllocationCapPercent,
  }) {
    _maxProfit = -1.0;
    _bestAllocations = [];
    _steps = [];
    _statesCount = 0;
    _bestUsedCapital = 0;
    _bestEtfPercent = 0;
    _bestBankPercent = 0;
    _bestRiskScore = 0;

    double timeFactor = 1.0;
    if (horizon == '1 month') timeFactor = 1 / 12;
    else if (horizon == '3 months') timeFactor = 3 / 12;
    else if (horizon == '6 months') timeFactor = 6 / 12;

    final maxRisk = riskLimits[riskPreference] ?? 6;
    final etfCapFraction = etfAllocationCapPercent.clamp(0, 100) / 100;

    final available = allOptions.where((opt) => opt.riskScore <= maxRisk).toList();

    _backtrack(available, 0, [], 0, capacity, timeFactor, maxRisk, etfCapFraction);

    return OptimizationResult(
      allocations: _bestAllocations,
      totalProfit: _maxProfit,
      steps: _steps,
      statesExplored: _statesCount,
      totalRiskScore: _bestRiskScore.toDouble(),
      maxRiskLimit: maxRisk,
      etfAllocationPercent: _bestEtfPercent,
      bankAllocationPercent: _bestBankPercent,
      usedCapital: _bestUsedCapital,
    );
  }

  void _backtrack(
    List<InvestmentOption> options,
    int index,
    List<InvestmentOption> current,
    int currentRisk,
    double capacity,
    double timeFactor,
    int maxRisk,
    double etfCapFraction,
  ) {
    _statesCount++;

    if (currentRisk > maxRisk) return;

    if (index == options.length) {
      if (current.isNotEmpty) {
        _evaluateSelection(current, capacity, timeFactor, etfCapFraction, maxRisk);
      }
      return;
    }

    // Include current option
    current.add(options[index]);
    _backtrack(options, index + 1, current,
        currentRisk + options[index].riskScore, capacity, timeFactor, maxRisk, etfCapFraction);

    // Backtrack
    _steps.add(TraceStep(
      type: StepType.backtrackInfo,
      title: 'Backtracking',
      description: 'Removing ${options[index].name} to explore other combinations',
    ));
    current.removeLast();

    // Exclude current option
    _backtrack(options, index + 1, current,
        currentRisk, capacity, timeFactor, maxRisk, etfCapFraction);
  }

  void _evaluateSelection(
    List<InvestmentOption> selection,
    double capacity,
    double timeFactor,
    double etfCapFraction,
    int maxRisk,
  ) {
    final selectedRisk = selection.fold<int>(0, (sum, opt) => sum + opt.riskScore);
    if (selectedRisk > maxRisk) {
      _steps.add(TraceStep(
        type: StepType.pruned,
        title: 'Risk Limit Exceeded',
        description: '${selection.map((e) => e.name).join(' + ')} exceeds max risk $maxRisk',
      ));
      return;
    }

    final etfOptions = selection.where((opt) => opt.type == InvestmentType.etf).toList();
    final bankOptions = selection.where((opt) => opt.type == InvestmentType.bank).toList();

    final etfBudget = capacity * etfCapFraction;
    final etfResult = _allocateCategory(etfOptions, etfBudget, timeFactor);
    final bankBudget = capacity - etfResult.usedBudget;
    final bankResult = _allocateCategory(bankOptions, bankBudget, timeFactor);

    if (!etfResult.valid || !bankResult.valid) {
      _steps.add(TraceStep(
        type: StepType.pruned,
        title: 'Insufficient Budget',
        description: '${selection.map((e) => e.name).join(' + ')} cannot meet minimum investments',
      ));
      return;
    }

    final totalProfit = etfResult.totalProfit + bankResult.totalProfit;
    final usedCapital = etfResult.usedBudget + bankResult.usedBudget;

    if (usedCapital <= 0) return;

    final actualEtfPercent = (etfResult.usedBudget / capacity) * 100;
    final actualBankPercent = (bankResult.usedBudget / capacity) * 100;

    final currentAllocations = [...etfResult.allocations, ...bankResult.allocations];
    currentAllocations.sort((a, b) => b.profit.compareTo(a.profit));

    bool isBetter = _bestAllocations.isEmpty ||
        totalProfit > _maxProfit ||
        (totalProfit == _maxProfit && usedCapital > _bestUsedCapital);

    _steps.add(TraceStep(
      type: StepType.evaluated,
      title: 'Evaluated',
      description: '${selection.map((e) => e.name).join(' + ')}',
      profit: totalProfit,
    ));

    if (!isBetter) return;

    _maxProfit = totalProfit;
    _bestAllocations = currentAllocations.asMap().entries.map((entry) {
      return Allocation(
        option: entry.value.option,
        amount: entry.value.amount,
        profit: entry.value.profit,
        rank: entry.key + 1,
      );
    }).toList();
    _bestUsedCapital = usedCapital;
    _bestEtfPercent = actualEtfPercent;
    _bestBankPercent = actualBankPercent;
    _bestRiskScore = selectedRisk;

    _steps.add(TraceStep(
      type: StepType.bestFound,
      title: 'New Best Found',
      description: '${selection.map((e) => e.name).join(' + ')} · Risk $selectedRisk/$maxRisk',
      profit: totalProfit,
    ));
  }

  _CategoryAllocationResult _allocateCategory(
    List<InvestmentOption> selected,
    double budget,
    double timeFactor,
  ) {
    if (selected.isEmpty) {
      return _CategoryAllocationResult(valid: true, usedBudget: 0, totalProfit: 0, allocations: []);
    }

    final totalMin = selected.fold<double>(0, (sum, opt) => sum + opt.minInvestment);
    if (totalMin > budget) {
      return _CategoryAllocationResult(valid: false, usedBudget: 0, totalProfit: 0, allocations: []);
    }

    final tempAllocations = selected
        .map((opt) => _TempAllocation(option: opt, amount: opt.minInvestment))
        .toList();
    double remaining = budget - totalMin;

    // Greedily allocate remaining budget to highest return option
    while (remaining > 0) {
      final best = tempAllocations.reduce((a, b) =>
          a.option.annualReturnRate >= b.option.annualReturnRate ? a : b);
      best.amount += remaining;
      remaining = 0;
    }

    final allocations = <Allocation>[];
    double totalProfit = 0;
    double usedBudget = 0;

    for (var alloc in tempAllocations) {
      final profit = alloc.amount * alloc.option.annualReturnRate * timeFactor;
      allocations.add(Allocation(
        option: alloc.option,
        amount: alloc.amount,
        profit: profit,
        rank: 0,
      ));
      totalProfit += profit;
      usedBudget += alloc.amount;
    }

    return _CategoryAllocationResult(
      valid: true,
      usedBudget: usedBudget,
      totalProfit: totalProfit,
      allocations: allocations,
    );
  }
}