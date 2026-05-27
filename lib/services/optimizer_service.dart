import '../models/investment_option.dart';

class OptimizationResult {
  final List<InvestmentOption> selectedOptions;
  final double totalProfit;
  final List<String> trace;
  final int nodesVisited;
  final int nodesPruned;

  OptimizationResult({
    required this.selectedOptions,
    required this.totalProfit,
    required this.trace,
    this.nodesVisited = 0,
    this.nodesPruned = 0,
  });
}

class OptimizerService {
  final List<InvestmentOption> allOptions = [
    // Banks: Weight (Min Deposit), Value (Return Rate)
    InvestmentOption(name: 'GoTyme', annualReturnRate: 0.06,  type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 500),
    InvestmentOption(name: 'Tonik',  annualReturnRate: 0.065, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 1000),
    InvestmentOption(name: 'Maya',   annualReturnRate: 0.035, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 100),
    InvestmentOption(name: 'CIMB',   annualReturnRate: 0.025, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 50),

    // ETFs: Usually require higher entry (Weights)
    InvestmentOption(name: 'QQQ', annualReturnRate: 0.21, type: InvestmentType.etf, riskLevel: 'Aggressive', minInvestment: 5000),
    InvestmentOption(name: 'VOO', annualReturnRate: 0.14, type: InvestmentType.etf, riskLevel: 'Moderate',   minInvestment: 3000),
    InvestmentOption(name: 'VTI', annualReturnRate: 0.13, type: InvestmentType.etf, riskLevel: 'Moderate',   minInvestment: 2500),
  ];

  List<String> _currentTrace = [];
  double _bestProfit = 0.0;
  List<InvestmentOption> _bestCombination = [];
  int _nodesVisited = 0;
  int _nodesPruned = 0;

  // FIX 1: Convert time horizon string to fraction of a year
  double _horizonToYearFraction(String horizon) {
    switch (horizon) {
      case '1 month':  return 1 / 12;
      case '3 months': return 3 / 12;
      case '6 months': return 6 / 12;
      case '1 year':   return 1.0;
      default:         return 1.0;
    }
  }

  OptimizationResult solveKnapsack({
    required double capacity,
    required String riskPreference,
    required String timeHorizon, // FIX 1: now required
    int? maxItems,               // FIX 2: wired from home.dart
  }) {
    _currentTrace = [];
    _bestProfit = 0.0;
    _bestCombination = [];
    _nodesVisited = 0;
    _nodesPruned = 0;

    final double yearFraction = _horizonToYearFraction(timeHorizon); // FIX 1

    // FIX 3: Aggressive now correctly filters only Aggressive options
    List<InvestmentOption> available = allOptions.where((opt) {
      if (riskPreference == 'Conservative') return opt.riskLevel == 'Conservative';
      if (riskPreference == 'Moderate')     return opt.riskLevel != 'Aggressive';
      if (riskPreference == 'Aggressive')   return true; // FIX 3: all options available
      return true;
    }).toList();

    // Sort by Value/Weight ratio (Greedy heuristic for pruning)
    available.sort((a, b) =>
        (b.value / b.minInvestment).compareTo(a.value / a.minInvestment));

    _currentTrace.add('Starting Knapsack Backtracking...');
    _currentTrace.add('Capacity: ₱${capacity.toStringAsFixed(2)}');
    _currentTrace.add('Time Horizon: $timeHorizon');
    _currentTrace.add('Risk Preference: $riskPreference');
    if (maxItems != null) _currentTrace.add('Max Options: $maxItems');

    _backtrack(available, 0, capacity, 0.0, [], maxItems, yearFraction);

    _currentTrace.add('Nodes visited: $_nodesVisited, pruned: $_nodesPruned');

    return OptimizationResult(
      selectedOptions: _bestCombination,
      totalProfit: _bestProfit,
      trace: _currentTrace,
      nodesVisited: _nodesVisited,
      nodesPruned: _nodesPruned,
    );
  }

  // FIX 1: Upper bound also scaled by yearFraction
  double _integerUpperBound(
    List<InvestmentOption> options,
    int startIndex,
    double remainingCapacity,
    double yearFraction,
  ) {
    double bound = 0.0;
    for (int i = startIndex; i < options.length && remainingCapacity > 0; i++) {
      final opt = options[i];
      if (opt.minInvestment <= remainingCapacity) {
        bound += opt.annualReturnRate * opt.minInvestment * yearFraction; // FIX 1
        remainingCapacity -= opt.minInvestment;
      }
    }
    return bound;
  }

  void _backtrack(
    List<InvestmentOption> options,
    int index,
    double remainingCapacity,
    double currentProfit,
    List<InvestmentOption> currentSelection,
    int? maxItems,
    double yearFraction, // FIX 1
  ) {
    _nodesVisited++;

    // No more items
    if (index == options.length) {
      if (currentProfit > _bestProfit) {
        _bestProfit = currentProfit;
        _bestCombination = List.from(currentSelection);
        _currentTrace.add('Found better combo: [${currentSelection.map((e) => e.name).join(", ")}] | Total Profit: ₱${_bestProfit.toStringAsFixed(2)}');
      }
      return;
    }

    InvestmentOption item = options[index];

    // Prune using integer upper bound
    double optimistic = currentProfit + _integerUpperBound(options, index, remainingCapacity, yearFraction);
    if (optimistic <= _bestProfit) {
      _nodesPruned++;
      _currentTrace.add('Pruned at index $index (optimistic ₱${optimistic.toStringAsFixed(2)} <= best ₱${_bestProfit.toStringAsFixed(2)})');
      return;
    }

    // FIX 2: Respect maxItems cap
    final bool canAddMore = maxItems == null || currentSelection.length < maxItems;

    // Branch 1: Include item if it fits
    if (item.minInvestment <= remainingCapacity && canAddMore) {
      double profitContribution = item.annualReturnRate * item.minInvestment * yearFraction; // FIX 1
      _currentTrace.add('Trying to INCLUDE ${item.name} (Cost: ₱${item.minInvestment.toStringAsFixed(2)}, Profit: ₱${profitContribution.toStringAsFixed(2)})');
      currentSelection.add(item);
      _backtrack(
        options,
        index + 1,
        remainingCapacity - item.minInvestment,
        currentProfit + profitContribution,
        currentSelection,
        maxItems,
        yearFraction,
      );
      currentSelection.removeLast(); // Backtrack
    } else if (!canAddMore) {
      _currentTrace.add('Max items reached; cannot include ${item.name}'); // FIX 2
    } else {
      _currentTrace.add('Cannot include ${item.name}: Too expensive');
    }

    // Branch 2: Exclude item
    _currentTrace.add('Skipping ${item.name}');
    _backtrack(
      options,
      index + 1,
      remainingCapacity,
      currentProfit,
      currentSelection,
      maxItems,
      yearFraction,
    );
  }
}