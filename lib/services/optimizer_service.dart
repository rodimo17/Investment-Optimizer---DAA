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
  final double highRateAmount;
  final double baseRateAmount;
  final double highRateProfit;
  final double baseRateProfit;
  final double profit;
  final int rank;

  Allocation({
    required this.option,
    required this.amount,
    required this.highRateAmount,
    required this.baseRateAmount,
    required this.highRateProfit,
    required this.baseRateProfit,
    required this.profit,
    required this.rank,
  });
}

class OptimizationResult {
  final List<Allocation> allocations;
  final double totalProfit;
  final List<TraceStep> steps;
  final int statesExplored;

  OptimizationResult({
    required this.allocations,
    required this.totalProfit,
    required this.steps,
    required this.statesExplored,
  });
}

class OptimizerService {
  final List<InvestmentOption> allOptions = [
    InvestmentOption(name: 'Maya Bank', annualReturnRate: 0.10, baseReturnRate: 0.035, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 100, interestCap: 100000, safetyRating: 8, liquidityScore: 10),
    InvestmentOption(name: 'SeaBank', annualReturnRate: 0.0425, baseReturnRate: 0.03, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 1, interestCap: 400000, safetyRating: 9, liquidityScore: 10),
    InvestmentOption(name: 'UNO Digital', annualReturnRate: 0.0425, baseReturnRate: 0.035, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 1, interestCap: 500000, safetyRating: 7, liquidityScore: 9),
    InvestmentOption(name: 'GoTyme Bank', annualReturnRate: 0.04, baseReturnRate: 0.04, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 500, safetyRating: 9, liquidityScore: 10),
    InvestmentOption(name: 'Tonik Bank', annualReturnRate: 0.04, baseReturnRate: 0.04, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 500, safetyRating: 8, liquidityScore: 8),
    InvestmentOption(name: 'CIMB Bank', annualReturnRate: 0.025, baseReturnRate: 0.025, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 50, safetyRating: 9, liquidityScore: 9),
    InvestmentOption(name: 'VOO ETF', annualReturnRate: 0.125, baseReturnRate: 0.125, type: InvestmentType.etf, riskLevel: 'Moderate', minInvestment: 2500, safetyRating: 9, liquidityScore: 7),
    InvestmentOption(name: 'VTI ETF', annualReturnRate: 0.12, baseReturnRate: 0.12, type: InvestmentType.etf, riskLevel: 'Moderate', minInvestment: 2500, safetyRating: 9, liquidityScore: 7),
    InvestmentOption(name: 'QQQ ETF', annualReturnRate: 0.18, baseReturnRate: 0.18, type: InvestmentType.etf, riskLevel: 'Aggressive', minInvestment: 5000, safetyRating: 8, liquidityScore: 7),
  ];

  double _maxProfit = -1.0;
  List<Allocation> _bestAllocations = [];
  List<TraceStep> _steps = [];
  int _statesCount = 0;

  Future<void> fetchLatestRates() async {
    // Simulating delay
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  OptimizationResult solveKnapsack({
    required double capacity,
    required String riskPreference,
    required String horizon,
    required int maxOptions,
  }) {
    _maxProfit = -1.0;
    _bestAllocations = [];
    _steps = [];
    _statesCount = 0;

    double timeFactor = 1.0;
    if (horizon == '1 month') {
      timeFactor = 1 / 12;
    } else if (horizon == '3 months') {
      timeFactor = 3 / 12;
    } else if (horizon == '6 months') {
      timeFactor = 6 / 12;
    }

    List<InvestmentOption> available = allOptions.where((opt) {
      if (riskPreference == 'Conservative') return opt.riskLevel == 'Conservative';
      if (riskPreference == 'Moderate') return opt.riskLevel != 'Aggressive';
      return true;
    }).toList();

    // Pure Backtracking for selection
    _backtrack(available, 0, [], capacity, maxOptions, timeFactor);

    return OptimizationResult(
      allocations: _bestAllocations,
      totalProfit: _maxProfit,
      steps: _steps,
      statesExplored: _statesCount,
    );
  }

  void _backtrack(List<InvestmentOption> options, int index, List<InvestmentOption> current, double capacity, int limit, double timeFactor) {
    _statesCount++;

    if (index == options.length || current.length == limit) {
      if (current.isNotEmpty) {
        _evaluateEqualTiered(current, capacity, timeFactor, limit);
      }
      return;
    }

    current.add(options[index]);
    _backtrack(options, index + 1, current, capacity, limit, timeFactor);
    
    _steps.add(TraceStep(
      type: StepType.backtrackInfo,
      title: 'Backtracking',
      description: 'Removing ${options[index].name} to explore other combinations',
    ));
    current.removeLast();

    _backtrack(options, index + 1, current, capacity, limit, timeFactor);
  }

  void _evaluateEqualTiered(List<InvestmentOption> selection, double totalCapacity, double timeFactor, int targetLimit) {
    // Every selected company gets an identical slice of capital
    double splitAmount = totalCapacity / selection.length;
    double currentTotalProfit = 0;
    List<Allocation> currentAllocations = [];

    for (var option in selection) {
      if (splitAmount < option.minInvestment) {
        _steps.add(TraceStep(
          type: StepType.pruned,
          title: 'Diversification Constraint',
          description: '${option.name} needs at least ₱${option.minInvestment}',
        ));
        return;
      }

      double highRateAmount = 0;
      double baseRateAmount = 0;
      double highRateProfit = 0;
      double baseRateProfit = 0;

      if (option.interestCap != null) {
        highRateAmount = splitAmount.clamp(0, option.interestCap!);
        baseRateAmount = (splitAmount - highRateAmount).clamp(0, double.infinity);
        
        highRateProfit = (highRateAmount * option.annualReturnRate) * timeFactor;
        baseRateProfit = (baseRateAmount * option.baseReturnRate) * timeFactor;
      } else {
        highRateAmount = splitAmount;
        highRateProfit = (splitAmount * option.annualReturnRate) * timeFactor;
      }

      double totalProfit = highRateProfit + baseRateProfit;
      currentTotalProfit += totalProfit;

      currentAllocations.add(Allocation(
        option: option,
        amount: splitAmount,
        highRateAmount: highRateAmount,
        baseRateAmount: baseRateAmount,
        highRateProfit: highRateProfit,
        baseRateProfit: baseRateProfit,
        profit: totalProfit,
        rank: 0,
      ));
    }

    bool isBetter = false;
    bool currentMeetsLimit = selection.length == targetLimit;
    
    if (_bestAllocations.isEmpty) {
      isBetter = true;
    } else {
      bool bestMeetsLimit = _bestAllocations.length == targetLimit;
      if (currentMeetsLimit && !bestMeetsLimit) {
        isBetter = true;
      } else if (currentMeetsLimit == bestMeetsLimit) {
        isBetter = currentTotalProfit > _maxProfit;
      }
    }

    if (isBetter) {
      _maxProfit = currentTotalProfit;
      currentAllocations.sort((a, b) => b.option.overallScore.compareTo(a.option.overallScore));
      _bestAllocations = currentAllocations.asMap().entries.map((e) {
        return Allocation(
          option: e.value.option,
          amount: e.value.amount,
          highRateAmount: e.value.highRateAmount,
          baseRateAmount: e.value.baseRateAmount,
          highRateProfit: e.value.highRateProfit,
          baseRateProfit: e.value.baseRateProfit,
          profit: e.value.profit,
          rank: e.key + 1,
        );
      }).toList();

      _steps.add(TraceStep(
        type: StepType.bestFound,
        title: currentMeetsLimit ? 'Optimal Diversified Selection' : 'Optimal Selection (Partial)',
        description: selection.map((e) => e.name).join(" + "),
        profit: currentTotalProfit,
      ));
    } else {
      _steps.add(TraceStep(
        type: StepType.evaluated,
        title: 'Explored Selection',
        description: selection.map((e) => e.name).join(" + "),
        profit: currentTotalProfit,
      ));
    }
  }
}
