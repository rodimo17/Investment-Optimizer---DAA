import 'dart:math';
import '../models/investment_option.dart';
import '../services/etf_price_service.dart';

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

class _KnapsackItem {
  final InvestmentOption option;
  final double amount;

  _KnapsackItem({required this.option, required this.amount});
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
    InvestmentOption(name: 'Maya Bank', annualReturnRate: 0.10, baseReturnRate: 0.035, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 100),
    InvestmentOption(name: 'SeaBank', annualReturnRate: 0.0425, baseReturnRate: 0.03, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 1),
    InvestmentOption(name: 'UNO Digital', annualReturnRate: 0.0425, baseReturnRate: 0.035, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 1),
    InvestmentOption(name: 'GoTyme Bank', annualReturnRate: 0.04, baseReturnRate: 0.04, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 500),
    InvestmentOption(name: 'Tonik Bank', annualReturnRate: 0.04, baseReturnRate: 0.04, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 500),
    InvestmentOption(name: 'CIMB Bank', annualReturnRate: 0.025, baseReturnRate: 0.025, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 50),
    InvestmentOption(name: 'VOO ETF', annualReturnRate: 0.125, baseReturnRate: 0.125, type: InvestmentType.etf, riskLevel: 'Moderate', minInvestment: 2500),
    InvestmentOption(name: 'VTI ETF', annualReturnRate: 0.12, baseReturnRate: 0.12, type: InvestmentType.etf, riskLevel: 'Moderate', minInvestment: 2500),
    InvestmentOption(name: 'QQQ ETF', annualReturnRate: 0.18, baseReturnRate: 0.18, type: InvestmentType.etf, riskLevel: 'Aggressive', minInvestment: 5000),
  ];

  double _maxProfit = 0.0;
  List<Allocation> _bestAllocations = [];
  List<TraceStep> _steps = [];
  int _statesCount = 0;

  Future<void> fetchLatestRates() async {
    final etfService = EtfPriceService();
    final realTimeEtfs = await etfService.fetchRealTimePrices();

    await Future.delayed(const Duration(milliseconds: 500));
    final random = Random();
    for (var i = 0; i < allOptions.length; i++) {
      final opt = allOptions[i];
      double newRate = opt.annualReturnRate;

      if (opt.type == InvestmentType.etf) {
        final match = realTimeEtfs.where((e) => opt.name.contains(e.ticker)).firstOrNull;
        if (match != null) {
          newRate = (opt.annualReturnRate + (match.monthlyChange / 100)).clamp(0.05, 0.30);
        }
      } else {
        double delta = (random.nextDouble() * 0.002) - 0.001;
        newRate = (opt.annualReturnRate + delta).clamp(0.01, 0.15);
      }

      allOptions[i] = InvestmentOption(
        name: opt.name,
        annualReturnRate: newRate,
        baseReturnRate: opt.baseReturnRate,
        type: opt.type,
        riskLevel: opt.riskLevel,
        minInvestment: opt.minInvestment,
      );
    }
  }

  OptimizationResult solveKnapsack({
    required double capacity,
    required String riskPreference,
    required String horizon,
    required int maxOptions,
  }) {
    _maxProfit = 0.0;
    _bestAllocations = [];
    _steps = [];
    _statesCount = 0;

    double timeFactor = 1.0;
    if (horizon == '1 month') timeFactor = 1 / 12;
    else if (horizon == '3 months') timeFactor = 3 / 12;
    else if (horizon == '6 months') timeFactor = 6 / 12;

    // Filter available options based on risk profiles
    List<InvestmentOption> available = allOptions.where((opt) {
      if (riskPreference == 'Conservative') return opt.riskLevel == 'Conservative';
      if (riskPreference == 'Moderate') return opt.riskLevel != 'Aggressive';
      return true;
    }).toList();

    available.sort((a, b) => b.annualReturnRate.compareTo(a.annualReturnRate));

    // Dynamic Portfolio Split Constraints based on Risk Preference
    double maxEtfBudget = capacity;
    double maxBankBudget = capacity;

    if (riskPreference == 'Moderate') {
      maxEtfBudget = capacity * 0.60;  // Max 60% in ETFs, forcing 40% into Banks
    } else if (riskPreference == 'Aggressive') {
      maxEtfBudget = capacity * 0.75;  // Max 75% in ETFs, forcing 25% into Banks
    } else {
      maxEtfBudget = 0.0;              // 100% Banks for Conservative
    }

    _backtrack(
      options: available,
      index: 0,
      current: [],
      remainingBudget: capacity,
      currentProfit: 0.0,
      limit: maxOptions,
      timeFactor: timeFactor,
      bankSpent: 0.0,
      etfSpent: 0.0,
      maxBankBudget: maxBankBudget,
      maxEtfBudget: maxEtfBudget,
    );

    return OptimizationResult(
      allocations: _bestAllocations,
      totalProfit: _maxProfit,
      steps: _steps,
      statesExplored: _statesCount,
    );
  }

  void _backtrack({
    required List<InvestmentOption> options,
    required int index,
    required List<_KnapsackItem> current,
    required double remainingBudget,
    required double currentProfit,
    required int limit,
    required double timeFactor,
    required double bankSpent,
    required double etfSpent,
    required double maxBankBudget,
    required double maxEtfBudget,
  }) {
    _statesCount++;

    if (current.isNotEmpty) {
      if (currentProfit > _maxProfit) {
        _maxProfit = currentProfit;
        _bestAllocations = _buildAllocations(current, timeFactor);
        _steps.add(TraceStep(
          type: StepType.bestFound,
          title: 'New best return combination',
          description: current.map((e) => '${e.option.name} (₱${e.amount.toStringAsFixed(0)})').join(' + '),
          profit: currentProfit,
        ));
      } else {
        if (_steps.length < 200) {
          _steps.add(TraceStep(
            type: StepType.evaluated,
            title: 'Explored selection',
            description: current.map((e) => e.option.name).join(' + '),
            profit: currentProfit,
          ));
        }
      }
    }

    if (index >= options.length || current.length == limit || remainingBudget <= 0) return;

    final upperBound = _computeUpperBound(
      options: options,
      fromIndex: index,
      currentProfit: currentProfit,
      limit: limit,
      remainingBudget: remainingBudget,
      timeFactor: timeFactor,
    );

    if (upperBound <= _maxProfit) {
      if (_steps.length < 200) {
        _steps.add(TraceStep(
          type: StepType.pruned,
          title: 'Pruned by upper bound',
          description: 'Even the best remaining combination cannot exceed ₱${upperBound.toStringAsFixed(2)}',
        ));
      }
      return;
    }

    for (var i = index; i < options.length; i++) {
      final option = options[i];
      if (remainingBudget < option.minInvestment) continue;

      // Determine budget safety limits for this specific asset category
      final isBank = option.type == InvestmentType.bank;
      final allowedForType = isBank ? (maxBankBudget - bankSpent) : (maxEtfBudget - etfSpent);
      if (allowedForType < option.minInvestment) continue;

      final slotsLeft = limit - current.length - 1;
      final reserve = _reserveBudgetForFutureSlots(options, i + 1, slotsLeft);
      
      double maxAlloc = remainingBudget - reserve;
      if (maxAlloc > allowedForType) maxAlloc = allowedForType; // Restrict to asset limit
      if (maxAlloc < option.minInvestment) continue;

      final allocations = _getAllocationSteps(option: option, maxAlloc: maxAlloc);
      for (final amount in allocations) {
        final profit = amount * option.annualReturnRate * timeFactor;
        current.add(_KnapsackItem(option: option, amount: amount));

        _backtrack(
          options: options,
          index: i + 1,
          current: current,
          remainingBudget: remainingBudget - amount,
          currentProfit: currentProfit + profit,
          limit: limit,
          timeFactor: timeFactor,
          bankSpent: bankSpent + (isBank ? amount : 0.0),
          etfSpent: etfSpent + (isBank ? 0.0 : amount),
          maxBankBudget: maxBankBudget,
          maxEtfBudget: maxEtfBudget,
        );

        current.removeLast();
      }

      if (_steps.length < 200) {
        _steps.add(TraceStep(
          type: StepType.backtrackInfo,
          title: 'Backtracking',
          description: 'Finished exploring ${option.name} allocations',
        ));
      }
    }
  }

  List<double> _getAllocationSteps({
    required InvestmentOption option,
    required double maxAlloc,
  }) {
    const double step = 2000.0; // Increased step size slightly to match chunkier allocation expectations
    final values = <double>[];
    double amount = option.minInvestment;
    while (amount < maxAlloc) {
      values.add(amount);
      amount += step;
    }
    values.add(maxAlloc.clamp(option.minInvestment, maxAlloc));
    return values;
  }

  double _computeUpperBound({
    required List<InvestmentOption> options,
    required int fromIndex,
    required double currentProfit,
    required int limit,
    required double remainingBudget,
    required double timeFactor,
  }) {
    if (remainingBudget <= 0 || fromIndex >= options.length) return currentProfit;
    final bestRate = options[fromIndex].annualReturnRate;
    return currentProfit + remainingBudget * bestRate * timeFactor;
  }

  double _reserveBudgetForFutureSlots(List<InvestmentOption> options, int startIndex, int slotsLeft) {
    if (slotsLeft <= 0 || startIndex >= options.length) return 0.0;
    final mins = options.sublist(startIndex).map((option) => option.minInvestment).toList()..sort();
    final take = min(slotsLeft, mins.length);
    return mins.take(take).fold(0.0, (sum, value) => sum + value);
  }

  List<Allocation> _buildAllocations(List<_KnapsackItem> items, double timeFactor) {
    final sorted = List<_KnapsackItem>.from(items)
      ..sort((a, b) => b.option.annualReturnRate.compareTo(a.option.annualReturnRate));

    return sorted.asMap().entries.map((entry) {
      final item = entry.value;
      final option = item.option;

      final double baseRate = option.baseReturnRate;
      final double baseRateProfit = item.amount * baseRate * timeFactor;
      final double totalProfit = item.amount * option.annualReturnRate * timeFactor;
      final double highRateProfit = max(0.0, totalProfit - baseRateProfit);

      return Allocation(
        option: option,
        amount: item.amount,
        highRateAmount: (option.annualReturnRate - baseRate) > 0 ? item.amount : 0.0,
        baseRateAmount: baseRate > 0 ? item.amount : 0.0,
        highRateProfit: highRateProfit,
        baseRateProfit: baseRateProfit,
        profit: totalProfit,
        rank: entry.key + 1,
      );
    }).toList();
  }
}