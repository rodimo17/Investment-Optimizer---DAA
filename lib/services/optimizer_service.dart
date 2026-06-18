import 'dart:ffi';

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

class OptimizerService {
  static const Map<String, int> riskLimits = {
    'Conservative': 3,
    'Moderate': 6,
    'Aggressive': 10,
  };

  // Default options with preset deposit amounts.
  // depositAmount is the fixed amount the user commits to this option.
  // This replaces minInvestment as the weight in the knapsack.
  final List<InvestmentOption> allOptions = [
    InvestmentOption(
      name: 'Maya Bank',
      annualReturnRate: 0.10,
      type: InvestmentType.bank,
      riskLevel: 'Conservative',
      riskScore: 1,
      minInvestment: 100,
      depositAmount: 20000,
    ),
    InvestmentOption(
      name: 'SeaBank',
      annualReturnRate: 0.0425,
      type: InvestmentType.bank,
      riskLevel: 'Conservative',
      riskScore: 1,
      minInvestment: 1,
      depositAmount: 5000,
    ),
    InvestmentOption(
      name: 'UNO Digital',
      annualReturnRate: 0.0425,
      type: InvestmentType.bank,
      riskLevel: 'Conservative',
      riskScore: 1,
      minInvestment: 1,
      depositAmount: 5000,
    ),
    InvestmentOption(
      name: 'GoTyme Bank',
      annualReturnRate: 0.04,
      type: InvestmentType.bank,
      riskLevel: 'Conservative',
      riskScore: 1,
      minInvestment: 500,
      depositAmount: 10000,
    ),
    InvestmentOption(
      name: 'Tonik Bank',
      annualReturnRate: 0.04,
      type: InvestmentType.bank,
      riskLevel: 'Conservative',
      riskScore: 1,
      minInvestment: 500,
      depositAmount: 8000,
    ),
    InvestmentOption(
      name: 'CIMB Bank',
      annualReturnRate: 0.025,
      type: InvestmentType.bank,
      riskLevel: 'Conservative',
      riskScore: 1,
      minInvestment: 50,
      depositAmount: 3000,
    ),
    InvestmentOption(
      name: 'VOO ETF',
      annualReturnRate: 0.125,
      type: InvestmentType.etf,
      riskLevel: 'Moderate',
      riskScore: 5,
      minInvestment: 2500,
      depositAmount: 15000,
    ),
    InvestmentOption(
      name: 'VTI ETF',
      annualReturnRate: 0.12,
      type: InvestmentType.etf,
      riskLevel: 'Moderate',
      riskScore: 2,
      minInvestment: 2500,
      depositAmount: 10000,
    ),
    InvestmentOption(
      name: 'QQQ ETF',
      annualReturnRate: 0.18,
      type: InvestmentType.etf,
      riskLevel: 'Aggressive',
      riskScore: 8,
      minInvestment: 5000,
      depositAmount: 20000,
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

  /// Solves the 0/1 knapsack problem using backtracking.
  ///
  /// Each option has a fixed [depositAmount] declared by the user.
  /// The algorithm decides which SUBSET of options to include such that:
  ///   - Total deposit amounts do not exceed [capacity]
  ///   - Total risk score does not exceed the limit for [riskPreference]
  ///   - Total profit (annualReturnRate × depositAmount × timeFactor) is maximized
  ///
  /// No greedy allocation step exists — amounts are fixed, making this
  /// a pure 0/1 knapsack solved by backtracking with pruning.
  ///
  /// [customOptions] — when provided (from home.dart's deposit text fields),
  /// these replace [allOptions] as the candidate set. Each option already has
  /// the user's deposit amount baked in, so the optimizer uses them directly.
  OptimizationResult solveKnapsack({
    required double capacity,
    required String riskPreference,
    required String horizon,
    List<InvestmentOption>? customOptions,
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

    // Use user-supplied options from the deposit text fields when provided,
    // falling back to the built-in defaults otherwise.
    final source = customOptions ?? allOptions;

    // Filter out options whose deposit amount alone already exceeds budget,
    // and options whose risk score exceeds the max — no point exploring them.
    final available = source.where((opt) =>
        opt.riskScore <= maxRisk &&
        opt.depositAmount <= capacity &&
        opt.depositAmount >= opt.minInvestment,
    ).toList();

    _backtrack(
      options: available,
      index: 0,
      currentSelections: [],
      currentRisk: 0,
      currentUsedBudget: 0,
      capacity: capacity,
      timeFactor: timeFactor,
      maxRisk: maxRisk,
    );

    return OptimizationResult(
      allocations: _bestAllocations,
      totalProfit: _maxProfit < 0 ? 0 : _maxProfit,
      steps: _steps,
      statesExplored: _statesCount,
      totalRiskScore: _bestRiskScore.toDouble(),
      maxRiskLimit: maxRisk,
      etfAllocationPercent: _bestEtfPercent,
      bankAllocationPercent: _bestBankPercent,
      usedCapital: _bestUsedCapital,
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
  }) {
    _statesCount++;

    // Pruning: risk already exceeded — no point going deeper
    if (currentRisk > maxRisk) {
      _steps.add(TraceStep(
        type: StepType.pruned,
        title: 'Risk Pruned',
        description: 'Risk $currentRisk exceeds limit $maxRisk — branch cut',
      ));
      return;
    }

    // Pruning: budget already exceeded
    if (currentUsedBudget > capacity) {
      _steps.add(TraceStep(
        type: StepType.pruned,
        title: 'Budget Pruned',
        description:
            '₱${currentUsedBudget.toStringAsFixed(0)} exceeds budget ₱${capacity.toStringAsFixed(0)} — branch cut',
      ));
      return;
    }

    // Base case: all options have been considered
    if (index == options.length) {
      if (currentSelections.isNotEmpty) {
        _evaluateSelection(
          selection: currentSelections,
          usedBudget: currentUsedBudget,
          capacity: capacity,
          timeFactor: timeFactor,
          currentRisk: currentRisk,
          maxRisk: maxRisk,
        );
      }
      return;
    }

    final option = options[index];

    // === INCLUDE this option ===
    currentSelections.add(option);
    _backtrack(
      options: options,
      index: index + 1,
      currentSelections: currentSelections,
      currentRisk: currentRisk + option.riskScore,
      currentUsedBudget: currentUsedBudget + option.depositAmount,
      capacity: capacity,
      timeFactor: timeFactor,
      maxRisk: maxRisk,
    );

    // === BACKTRACK: remove and try without ===
    _steps.add(TraceStep(
      type: StepType.backtrackInfo,
      title: 'Backtracking',
      description: 'Removing ${option.name} (₱${option.depositAmount.toStringAsFixed(0)}) to explore other combinations',
    ));
    currentSelections.removeLast();

    // === EXCLUDE this option ===
    _backtrack(
      options: options,
      index: index + 1,
      currentSelections: currentSelections,
      currentRisk: currentRisk,
      currentUsedBudget: currentUsedBudget,
      capacity: capacity,
      timeFactor: timeFactor,
      maxRisk: maxRisk,
    );
  }

  void _evaluateSelection({
    required List<InvestmentOption> selection,
    required double usedBudget,
    required double capacity,
    required double timeFactor,
    required int currentRisk,
    required int maxRisk,
  }) {
    // Compute profit for each option using its fixed deposit amount
    final allocations = selection.map((opt) {
      final profit = opt.depositAmount * opt.annualReturnRate * timeFactor;
      return Allocation(
        option: opt,
        amount: opt.depositAmount,
        profit: profit,
        rank: 0,
      );
    }).toList();

    final totalProfit = allocations.fold<double>(0, (sum, a) => sum + a.profit);

    // Calculate ETF vs bank split percentages
    final etfUsed = allocations
        .where((a) => a.option.type == InvestmentType.etf)
        .fold<double>(0, (sum, a) => sum + a.amount);
    final bankUsed = allocations
        .where((a) => a.option.type == InvestmentType.bank)
        .fold<double>(0, (sum, a) => sum + a.amount);

    final etfPercent = capacity > 0 ? (etfUsed / capacity) * 100 : 0.0;
    final bankPercent = capacity > 0 ? (bankUsed / capacity) * 100 : 0.0;

    _steps.add(TraceStep(
      type: StepType.evaluated,
      title: 'Evaluated',
      description:
          '${selection.map((e) => e.name).join(' + ')} · ₱${usedBudget.toStringAsFixed(0)} used',
      profit: totalProfit,
    ));

    final isBetter = _bestAllocations.isEmpty ||
        totalProfit > _maxProfit ||
        (totalProfit == _maxProfit && usedBudget > _bestUsedCapital);

    if (!isBetter) return;

    _maxProfit = totalProfit;
    _bestUsedCapital = usedBudget;
    _bestEtfPercent = etfPercent.toDouble();
    _bestBankPercent = bankPercent.toDouble();
    _bestRiskScore = currentRisk;

    // Rank by profit descending
    allocations.sort((a, b) => b.profit.compareTo(a.profit));
    _bestAllocations = allocations.asMap().entries.map((entry) {
      return Allocation(
        option: entry.value.option,
        amount: entry.value.amount,
        profit: entry.value.profit,
        rank: entry.key + 1,
      );
    }).toList();

    _steps.add(TraceStep(
      type: StepType.bestFound,
      title: 'New Best Found',
      description:
          '${selection.map((e) => e.name).join(' + ')} · Profit ₱${totalProfit.toStringAsFixed(0)} · Risk $currentRisk/$maxRisk',
      profit: totalProfit,
    ));
  }
}