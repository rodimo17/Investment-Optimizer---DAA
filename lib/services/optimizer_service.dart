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
    InvestmentOption(name: 'GoTyme', annualReturnRate: 0.06, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 500),
    InvestmentOption(name: 'Tonik', annualReturnRate: 0.065, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 1000),
    InvestmentOption(name: 'Maya', annualReturnRate: 0.035, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 100),
    InvestmentOption(name: 'CIMB', annualReturnRate: 0.025, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 50),
    
    // ETFs: Usually require higher entry (Weights)
    InvestmentOption(name: 'QQQ', annualReturnRate: 0.21, type: InvestmentType.etf, riskLevel: 'Aggressive', minInvestment: 5000),
    InvestmentOption(name: 'VOO', annualReturnRate: 0.14, type: InvestmentType.etf, riskLevel: 'Moderate', minInvestment: 3000),
    InvestmentOption(name: 'VTI', annualReturnRate: 0.13, type: InvestmentType.etf, riskLevel: 'Moderate', minInvestment: 2500),
  ];

  List<String> _currentTrace = [];
  double _bestProfit = 0.0; // currency profit 
  List<InvestmentOption> _bestCombination = [];
  int _nodesVisited = 0;
  int _nodesPruned = 0;

  OptimizationResult solveKnapsack({
    required double capacity, // User's Total Capital
    required String riskPreference,
    int? maxItems, // optional cap on number of allocations
  }) {
    _currentTrace = [];
    _bestProfit = 0.0;
    _bestCombination = [];
    _nodesVisited = 0;
    _nodesPruned = 0;

    // 1. Pre-filter by risk
    List<InvestmentOption> available = allOptions.where((opt) {
      if (riskPreference == 'Conservative') return opt.riskLevel == 'Conservative';
      if (riskPreference == 'Moderate') return opt.riskLevel != 'Aggressive';
     // if (riskPreference == 'Aggressive') return opt.riskLevel == 'Aggressive';
      return true;
    }).toList();

    // 2. Sort by Value/Weight ratio (Greedy heuristic for pruning)
    available.sort((a, b) => (b.value / b.minInvestment).compareTo(a.value / a.minInvestment));

    _currentTrace.add('Starting Knapsack Backtracking...');
    _currentTrace.add('Capacity: ₱${capacity.toStringAsFixed(2)}');

    _backtrack(available, 0, capacity, 0.0, [], maxItems);

    _currentTrace.add('Nodes visited: $_nodesVisited, pruned: $_nodesPruned');

    return OptimizationResult(
      selectedOptions: _bestCombination,
      totalProfit: _bestProfit,
      trace: _currentTrace,
      nodesVisited: _nodesVisited,
      nodesPruned: _nodesPruned,
    );
  }
  double _integerUpperBound(List<InvestmentOption> options, int startIndex, double remainingCapacity) {
    // optimistic upper bound using whole-item greedy addition 
    double bound = 0.0;
    for (int i = startIndex; i < options.length && remainingCapacity > 0; i++) {
      final opt = options[i];
      if (opt.minInvestment <= remainingCapacity) {
        bound += opt.annualReturnRate * opt.minInvestment; // add whole item's profit
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
    double optimistic = currentProfit + _integerUpperBound(options, index, remainingCapacity);
    if (optimistic <= _bestProfit) {
      _nodesPruned++;
      _currentTrace.add('Pruned at index $index (optimistic ₱${optimistic.toStringAsFixed(2)} <= best ₱${_bestProfit.toStringAsFixed(2)})');
      return;
    }

    // Branch 1: Include item if it fits
    if (item.minInvestment <= remainingCapacity) {
      if (maxItems == null || currentSelection.length < maxItems) {
        double profitContribution = item.annualReturnRate * item.minInvestment; // annual profit in currency
        _currentTrace.add('Trying to INCLUDE ${item.name} (Cost: ₱${item.minInvestment.toStringAsFixed(2)}, Profit: ₱${profitContribution.toStringAsFixed(2)})');
        currentSelection.add(item);
        _backtrack(
          options,
          index + 1,
          remainingCapacity - item.minInvestment,
          currentProfit + profitContribution,
          currentSelection,
          maxItems,
        );
        currentSelection.removeLast(); // Backtrack
      } else {
        _currentTrace.add('Max items reached; cannot include ${item.name}');
      }
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
    );
  }
}
