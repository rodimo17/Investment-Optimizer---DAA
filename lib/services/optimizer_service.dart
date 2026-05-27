import '../models/investment_option.dart';

class OptimizationResult {
  final List<InvestmentOption> selectedOptions;
  final double totalProfit;
  final List<String> trace;

  OptimizationResult({
    required this.selectedOptions,
    required this.totalProfit,
    required this.trace,
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
  double _maxReturn = 0.0;
  List<InvestmentOption> _bestCombination = [];

  OptimizationResult solveKnapsack({
    required double capacity, // User's Total Capital
    required String riskPreference,
  }) {
    _currentTrace = [];
    _maxReturn = 0.0;
    _bestCombination = [];

    // 1. Pre-filter by risk
    List<InvestmentOption> available = allOptions.where((opt) {
      if (riskPreference == 'Conservative') return opt.riskLevel == 'Conservative';
      if (riskPreference == 'Moderate') return opt.riskLevel != 'Aggressive';
      return true;
    }).toList();

    // 2. Sort by Value/Weight ratio (Greedy heuristic for pruning)
    available.sort((a, b) => (b.value / b.minInvestment).compareTo(a.value / a.minInvestment));

    _currentTrace.add('Starting Knapsack Backtracking...');
    _currentTrace.add('Capacity: ₱$capacity');
    
    _backtrack(available, 0, capacity, 0.0, []);

    return OptimizationResult(
      selectedOptions: _bestCombination,
      totalProfit: _maxReturn,
      trace: _currentTrace,
    );
  }

  void _backtrack(
    List<InvestmentOption> options,
    int index,
    double remainingCapacity,
    double currentReturn,
    List<InvestmentOption> currentSelection,
  ) {
    // Base Case: No more items or no more capacity
    if (index == options.length) {
      if (currentReturn > _maxReturn) {
        _maxReturn = currentReturn;
        _bestCombination = List.from(currentSelection);
        _currentTrace.add('Found better combo: [${currentSelection.map((e) => e.name).join(", ")}] | Total Rate: ${(_maxReturn * 100).toStringAsFixed(2)}%');
      }
      return;
    }

    InvestmentOption item = options[index];

    // Branch 1: Include item (if it fits)
    if (item.minInvestment <= remainingCapacity) {
      _currentTrace.add('Trying to INCLUDE ${item.name} (Cost: ${item.minInvestment})');
      currentSelection.add(item);
      _backtrack(
        options,
        index + 1,
        remainingCapacity - item.minInvestment,
        currentReturn + item.annualReturnRate,
        currentSelection,
      );
      currentSelection.removeLast(); // Backtrack
    } else {
      _currentTrace.add('Cannot include ${item.name}: Too expensive');
    }

    // Branch 2: Exclude item
    _currentTrace.add('Skipping ${item.name}');
    _backtrack(
      options,
      index + 1,
      remainingCapacity,
      currentReturn,
      currentSelection,
    );
  }
}
