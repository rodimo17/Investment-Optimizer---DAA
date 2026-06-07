import '../models/investment_option.dart';

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
  final double amount;
  final double profit;

  Allocation({required this.option, required this.amount, required this.profit});
}

class OptimizationResult {
  final List<Allocation> allocations;
  final double totalProfit;
  final List<TraceStep> steps;

  OptimizationResult({
    required this.allocations,
    required this.totalProfit,
    required this.steps,
  });
}

class OptimizerService {
  final List<InvestmentOption> allOptions = [
    InvestmentOption(name: 'GoTyme Bank', annualReturnRate: 0.04, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 500),
    InvestmentOption(name: 'Maya Bank', annualReturnRate: 0.08, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 100),
    InvestmentOption(name: 'Tonik Bank', annualReturnRate: 0.05, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 500),
    InvestmentOption(name: 'VOO ETF', annualReturnRate: 0.125, type: InvestmentType.etf, riskLevel: 'Moderate', minInvestment: 2500),
    InvestmentOption(name: 'VTI ETF', annualReturnRate: 0.12, type: InvestmentType.etf, riskLevel: 'Moderate', minInvestment: 2500),
    InvestmentOption(name: 'QQQ ETF', annualReturnRate: 0.18, type: InvestmentType.etf, riskLevel: 'Aggressive', minInvestment: 5000),
  ];

  double _maxProfit = -1.0;
  List<InvestmentOption> _bestCombo = [];
  List<TraceStep> _steps = [];

  OptimizationResult solveKnapsack({
    required double capacity,
    required String riskPreference,
    required String horizon,
    required int maxOptions,
  }) {
    _maxProfit = -1.0;
    _bestCombo = [];
    _steps = [];

    double timeFactor = horizon == '1 month' ? 1/12 : horizon == '3 months' ? 3/12 : horizon == '6 months' ? 6/12 : 1.0;

    List<InvestmentOption> available = allOptions.where((opt) {
      if (riskPreference == 'Conservative') return opt.riskLevel == 'Conservative';
      if (riskPreference == 'Moderate') return opt.riskLevel != 'Aggressive';
      return true;
    }).toList();

    _backtrack(available, 0, [], capacity, maxOptions, timeFactor);

    List<Allocation> finalAllocations = [];
    if (_bestCombo.isNotEmpty) {
      double splitAmount = capacity / _bestCombo.length;
      for (var item in _bestCombo) {
        finalAllocations.add(Allocation(
          option: item,
          amount: splitAmount,
          profit: splitAmount * (item.annualReturnRate * timeFactor),
        ));
      }
    }

    return OptimizationResult(
      allocations: finalAllocations,
      totalProfit: _maxProfit,
      steps: _steps,
    );
  }

  void _backtrack(List<InvestmentOption> options, int index, List<InvestmentOption> current, double capacity, int limit, double timeFactor) {
    if (index == options.length || current.length == limit) {
      if (current.isNotEmpty) {
        bool hasBank = current.any((o) => o.type == InvestmentType.bank);
        bool hasEtf = current.any((o) => o.type == InvestmentType.etf);

        String comboName = current.map((e) => e.name).join(" + ");

        if (limit > 1 && (!hasBank || !hasEtf)) {
          return;
        }

        double splitAmount = capacity / current.length;
        if (current.every((o) => splitAmount >= o.minInvestment)) {
          double currentP = 0;
          for (var o in current) {
            currentP += splitAmount * (o.annualReturnRate * timeFactor);
          }

          if (currentP > _maxProfit) {
            _maxProfit = currentP;
            _bestCombo = List.from(current);
            _steps.add(TraceStep(
              type: StepType.bestFound,
              title: 'New Optimal Combo Found',
              description: comboName,
              profit: currentP,
            ));
          } else {
            _steps.add(TraceStep(
              type: StepType.evaluated,
              title: 'Evaluated Pairing',
              description: comboName,
              profit: currentP,
            ));
          }
        } else {
          _steps.add(TraceStep(
            type: StepType.pruned,
            title: 'Combination Pruned',
            description: '$comboName (Insufficient capital for minimums)',
          ));
        }
      }
      return;
    }

    current.add(options[index]);
    _backtrack(options, index + 1, current, capacity, limit, timeFactor);
    current.removeLast();
    _backtrack(options, index + 1, current, capacity, limit, timeFactor);
  }
}
