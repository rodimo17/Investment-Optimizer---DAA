import '../models/investment_option.dart';

/// Required on InvestmentOption: name (String), annualReturnRate (double),
/// type (InvestmentType), riskLevel (String), riskScore (int),
/// minInvestment (double), depositAmount (double), and
/// copyWith({double? depositAmount}).

enum StepType { evaluated, pruned, bestFound }

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
  final int amount;
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
  final int branchesPruned;
  final int totalRiskScore;
  final int maxRiskLimit;
  final double etfAllocationPercent;
  final double bankAllocationPercent;
  final double usedCapital;
  final bool metDiversificationFloor;

  OptimizationResult({
    required this.allocations,
    required this.totalProfit,
    required this.steps,
    required this.statesExplored,
    required this.branchesPruned,
    required this.totalRiskScore,
    required this.maxRiskLimit,
    required this.etfAllocationPercent,
    required this.bankAllocationPercent,
    required this.usedCapital,
    required this.metDiversificationFloor,
  });
}

class OptimizerService {
  static final OptimizerService _instance = OptimizerService._internal();
  factory OptimizerService() => _instance;
  OptimizerService._internal();

  static const Map<String, int> riskLimits = {
    'Conservative': 3,
    'Moderate': 6,
    'Aggressive': 10,
  };

  final List<InvestmentOption> allOptions = [
    InvestmentOption(name: 'Maya Bank', annualReturnRate: 0.10, type: InvestmentType.bank, riskLevel: 'Conservative', riskScore: 1, minInvestment: 100, depositAmount: 0),
    InvestmentOption(name: 'SeaBank', annualReturnRate: 0.0425, type: InvestmentType.bank, riskLevel: 'Conservative', riskScore: 1, minInvestment: 1, depositAmount: 0),
    InvestmentOption(name: 'UNO Digital', annualReturnRate: 0.0425, type: InvestmentType.bank, riskLevel: 'Conservative', riskScore: 1, minInvestment: 1, depositAmount: 0),
    InvestmentOption(name: 'GoTyme Bank', annualReturnRate: 0.04, type: InvestmentType.bank, riskLevel: 'Conservative', riskScore: 1, minInvestment: 500, depositAmount: 0),
    InvestmentOption(name: 'Tonik Bank', annualReturnRate: 0.04, type: InvestmentType.bank, riskLevel: 'Conservative', riskScore: 1, minInvestment: 500, depositAmount: 0),
    InvestmentOption(name: 'CIMB Bank', annualReturnRate: 0.025, type: InvestmentType.bank, riskLevel: 'Conservative', riskScore: 1, minInvestment: 50, depositAmount: 0),
    InvestmentOption(name: 'VOO ETF', annualReturnRate: 0.125, type: InvestmentType.etf, riskLevel: 'Moderate', riskScore: 5, minInvestment: 2500, depositAmount: 0),
    InvestmentOption(name: 'VTI ETF', annualReturnRate: 0.12, type: InvestmentType.etf, riskLevel: 'Moderate', riskScore: 2, minInvestment: 2500, depositAmount: 0),
    InvestmentOption(name: 'QQQ ETF', annualReturnRate: 0.18, type: InvestmentType.etf, riskLevel: 'Aggressive', riskScore: 8, minInvestment: 5000, depositAmount: 0),
  ];

  double _maxProfit = -1.0;
  List<Allocation> _bestAllocations = [];
  List<TraceStep> _steps = [];
  int _statesCount = 0;
  int _prunedCount = 0;
  double _bestUsedCapital = 0;
  int _bestRiskScore = 0;

  /// Computes a starting deposit for each option by splitting [capacity]
  /// evenly across [targetCount] slots. This is just a default shown in the
  /// UI's text fields — the user can edit individual amounts before
  /// solveKnapsack runs. Whatever's set when it runs is treated as final.
  List<InvestmentOption> generateDefaultDeposits({
    required List<InvestmentOption> options,
    required double capacity,
    required int targetCount,
  }) {
    if (options.isEmpty) return options;
    final n = targetCount.clamp(1, options.length);
    final int defaultAmount = (capacity / n).toInt();
    return options.map((o) => o.copyWith(depositAmount: defaultAmount)).toList();
  }

  /// Solves a 3-constraint 0/1 knapsack via backtracking with pruning.
  ///
  /// Each option carries a fixed [depositAmount] — the real weight in the
  /// knapsack sense. The algorithm picks a SUBSET of options such that:
  ///   1. Total deposits do not exceed [capacity]                  (hard)
  ///   2. Total risk score does not exceed the [riskPreference] limit (hard)
  ///   3. At least [minOptions] assets are included, if feasible at all (soft)
  ///   4. Total profit is maximized among combinations meeting the above
  OptimizationResult solveKnapsack({
    required double capacity,
    required String riskPreference,
    required String horizon,
    required int minOptions,
    int? maxOptions,
    List<InvestmentOption>? customOptions,
  }) {
    _maxProfit = -1.0;
    _bestAllocations = [];
    _steps = [];
    _statesCount = 0;
    _prunedCount = 0;
    _bestUsedCapital = 0;
    _bestRiskScore = 0;

    double timeFactor = 1.0;
    if (horizon == '1 month') timeFactor = 1 / 12;
    else if (horizon == '3 months') timeFactor = 3 / 12;
    else if (horizon == '6 months') timeFactor = 6 / 12;

    final maxRisk = riskLimits[riskPreference] ?? 6;
    final source = customOptions ?? allOptions;

    // Pre-filter: skip options that are individually already infeasible.
    final available = source.where((opt) =>
        opt.riskScore <= maxRisk &&
        opt.depositAmount <= capacity &&
        opt.depositAmount >= opt.minInvestment
    ).toList();

    if (available.isEmpty) {
      return OptimizationResult(
        allocations: [], totalProfit: 0, steps: _steps, statesExplored: 0,
        branchesPruned: 0, totalRiskScore: 0, maxRiskLimit: maxRisk,
        etfAllocationPercent: 0, bankAllocationPercent: 0, usedCapital: 0,
        metDiversificationFloor: false,
      );
    }

    final effectiveMax = (maxOptions ?? available.length).clamp(1, available.length);
    final effectiveMin = minOptions.clamp(1, effectiveMax);

    _backtrack(
      options: available,
      index: 0,
      currentSelections: [],
      currentRisk: 0,
      currentUsedBudget: 0,
      capacity: capacity,
      timeFactor: timeFactor,
      maxRisk: maxRisk,
      minOptions: effectiveMin,
      maxOptions: effectiveMax,
    );

    final etfUsed = _bestAllocations.where((a) => a.option.type == InvestmentType.etf).fold<double>(0, (s, a) => s + a.amount);
    final bankUsed = _bestAllocations.where((a) => a.option.type == InvestmentType.bank).fold<double>(0, (s, a) => s + a.amount);

    return OptimizationResult(
      allocations: _bestAllocations,
      totalProfit: _maxProfit < 0 ? 0 : _maxProfit,
      steps: _steps,
      statesExplored: _statesCount,
      branchesPruned: _prunedCount,
      totalRiskScore: _bestRiskScore,
      maxRiskLimit: maxRisk,
      etfAllocationPercent: capacity > 0 ? (etfUsed / capacity) * 100 : 0,
      bankAllocationPercent: capacity > 0 ? (bankUsed / capacity) * 100 : 0,
      usedCapital: _bestUsedCapital,
      metDiversificationFloor: _bestAllocations.length >= effectiveMin,
    );
  }

  void _backtrack({
    required List<InvestmentOption> options,
    required int index,
    required List<InvestmentOption> currentSelections,
    required int currentRisk,
    required double currentUsedBudget,
    required double capacity,
    required double timeFactor,
    required int maxRisk,
    required int minOptions,
    required int maxOptions,
  }) {
    _statesCount++;

    // Soft prune: once a floor-meeting best exists, cut any branch that can
    // never reach the floor itself — it can never outrank that best.
    final remainingItems = options.length - index;
    final canReachFloor = currentSelections.length + remainingItems >= minOptions;
    final bestMeetsFloor = _bestAllocations.length >= minOptions;
    if (bestMeetsFloor && !canReachFloor) {
      _prunedCount++;
      _steps.add(TraceStep(
        type: StepType.pruned,
        title: 'Diversification Pruned',
        description: 'Cannot reach the minimum of $minOptions assets from here — branch cut',
      ));
      return;
    }

    if (currentSelections.length == maxOptions || index == options.length) {
      if (currentSelections.isNotEmpty) {
        _evaluateSelection(
          selection: currentSelections,
          usedBudget: currentUsedBudget,
          timeFactor: timeFactor,
          currentRisk: currentRisk,
          minOptions: minOptions,
        );
      }
      return;
    }

    final option = options[index];
    final newRisk = currentRisk + option.riskScore;
    final newBudget = currentUsedBudget + option.depositAmount;

    // Hard prune, checked BEFORE including — matches "if weight[n] > W,
    // case 1 (exclude) is the only possibility," no wasted recursive call.
    if (newRisk <= maxRisk && newBudget <= capacity) {
      currentSelections.add(option);
      _backtrack(
        options: options, index: index + 1, currentSelections: currentSelections,
        currentRisk: newRisk, currentUsedBudget: newBudget, capacity: capacity,
        timeFactor: timeFactor, maxRisk: maxRisk, minOptions: minOptions, maxOptions: maxOptions,
      );
      currentSelections.removeLast();
    } else {
      _prunedCount++;
      _steps.add(TraceStep(
        type: StepType.pruned,
        title: 'Budget/Risk Pruned',
        description: 'Including ${option.name} would exceed budget or risk — only exclude possible',
      ));
    }

    _backtrack(
      options: options, index: index + 1, currentSelections: currentSelections,
      currentRisk: currentRisk, currentUsedBudget: currentUsedBudget, capacity: capacity,
      timeFactor: timeFactor, maxRisk: maxRisk, minOptions: minOptions, maxOptions: maxOptions,
    );
  }

  void _evaluateSelection({
    required List<InvestmentOption> selection,
    required double usedBudget,
    required double timeFactor,
    required int currentRisk,
    required int minOptions,
  }) {
    final allocations = selection.map((opt) {
      final profit = opt.depositAmount * opt.annualReturnRate * timeFactor;
      return Allocation(option: opt, amount: opt.depositAmount, profit: profit, rank: 0);
    }).toList();

    final totalProfit = allocations.fold<double>(0, (sum, a) => sum + a.profit);

    _steps.add(TraceStep(
      type: StepType.evaluated,
      title: 'Evaluated',
      description: '${selection.map((e) => e.name).join(" + ")} · ₱${usedBudget.toStringAsFixed(0)} used',
      profit: totalProfit,
    ));

    final meetsFloorNew = selection.length >= minOptions;
    final meetsFloorBest = _bestAllocations.length >= minOptions;

    bool isBetter;
    if (_bestAllocations.isEmpty) {
      isBetter = true;
    } else if (meetsFloorNew != meetsFloorBest) {
      isBetter = meetsFloorNew; // floor-meeting always outranks sub-floor
    } else {
      isBetter = totalProfit > _maxProfit ||
          (totalProfit == _maxProfit && usedBudget > _bestUsedCapital);
    }

    if (!isBetter) return;

    _maxProfit = totalProfit;
    _bestUsedCapital = usedBudget;
    _bestRiskScore = currentRisk;

    allocations.sort((a, b) => b.profit.compareTo(a.profit));
    _bestAllocations = allocations.asMap().entries.map((e) {
      return Allocation(option: e.value.option, amount: e.value.amount, profit: e.value.profit, rank: e.key + 1);
    }).toList();

    _steps.add(TraceStep(
      type: StepType.bestFound,
      title: 'New Best Found',
      description: '${selection.map((e) => e.name).join(" + ")} · Profit ₱${totalProfit.toStringAsFixed(0)} · Risk $currentRisk',
      profit: totalProfit,
    ));
  }
}