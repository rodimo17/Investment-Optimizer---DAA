import 'dart:math';
import '../models/investment_option.dart';
import 'etf_price_service.dart';

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
  final int branchesPruned;

  OptimizationResult({
    required this.allocations,
    required this.totalProfit,
    required this.steps,
    required this.statesExplored,
    required this.branchesPruned,
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
  int _prunedCount = 0;

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
        interestCap: opt.interestCap,
        safetyRating: opt.safetyRating,
        liquidityScore: opt.liquidityScore,
      );
    }
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
    _prunedCount = 0;

    double timeFactor = 1.0;
    if (horizon == '1 month') timeFactor = 1 / 12;
    else if (horizon == '3 months') timeFactor = 3 / 12;
    else if (horizon == '6 months') timeFactor = 6 / 12;

    List<InvestmentOption> available = allOptions.where((opt) {
      if (riskPreference == 'Conservative') return opt.riskLevel == 'Conservative';
      if (riskPreference == 'Moderate') return opt.riskLevel != 'Aggressive';
      return true;
    }).toList();

    available.sort((a, b) => b.annualReturnRate.compareTo(a.annualReturnRate));

    _backtrack(available, 0, [], capacity, maxOptions, timeFactor);

    return OptimizationResult(
      allocations: _bestAllocations,
      totalProfit: _maxProfit,
      steps: _steps,
      statesExplored: _statesCount,
      branchesPruned: _prunedCount,
    );
  }

  void _backtrack(List<InvestmentOption> options, int index, List<InvestmentOption> current, double capacity, int limit, double timeFactor) {
    _statesCount++;

    // Base case: we have enough items or we ran out of options
    if (current.length == limit || index == options.length) {
      if (current.isNotEmpty) {
        _evaluateEqualTiered(current, capacity, timeFactor, limit);
      }
      return;
    }

    // --- DAA BOUNDING FUNCTION ---
    // Calculate best possible profit from here
    double currentP = _calculateCurrentProfit(current, capacity, timeFactor);
    double potentialP = _calculateRemainingBound(options, index, capacity, limit - current.length, timeFactor);
    
    // Prune if this branch can't beat our best, OR if it's less diversified than our best found so far
    if (_bestAllocations.length == limit && (currentP + potentialP) <= _maxProfit) {
      _prunedCount++;
      return;
    }

    // Path 1: Include (Only if it doesn't exceed limit)
    if (current.length < limit) {
      current.add(options[index]);
      _backtrack(options, index + 1, current, capacity, limit, timeFactor);
      current.removeLast();
    }
    
    // Path 2: Exclude
    _backtrack(options, index + 1, current, capacity, limit, timeFactor);
  }

  double _calculateCurrentProfit(List<InvestmentOption> selection, double totalCapacity, double timeFactor) {
    if (selection.isEmpty) return 0;
    double splitAmount = totalCapacity / selection.length;
    double profit = 0;
    for (var opt in selection) {
      profit += (splitAmount * opt.annualReturnRate) * timeFactor;
    }
    return profit;
  }

  double _calculateRemainingBound(List<InvestmentOption> options, int startIndex, double capacity, int slotsLeft, double timeFactor) {
    double bound = 0;
    // Greedy assumption: remaining capital is split equally among the best remaining options
    double splitAmount = capacity / (slotsLeft > 0 ? slotsLeft : 1);
    for (int i = startIndex; i < options.length && i < startIndex + slotsLeft; i++) {
      bound += (splitAmount * options[i].annualReturnRate) * timeFactor;
    }
    return bound;
  }

  void _evaluateEqualTiered(List<InvestmentOption> selection, double totalCapacity, double timeFactor, int targetLimit) {
    double splitAmount = totalCapacity / selection.length;
    double currentTotalProfit = 0;
    List<Allocation> currentAllocations = [];

    for (var option in selection) {
      if (splitAmount < option.minInvestment) return;

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

    // THE DIVERSIFICATION RULE: 
    // 1. If this combo has MORE assets than our current best, it's better (even if profit is slightly lower)
    // 2. If it has SAME assets, pick the one with MORE profit.
    bool isBetter = false;
    if (_bestAllocations.isEmpty) {
      isBetter = true;
    } else if (selection.length > _bestAllocations.length) {
      isBetter = true;
    } else if (selection.length == _bestAllocations.length) {
      isBetter = currentTotalProfit > _maxProfit;
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
        title: 'Optimal Diversified Strategy Found',
        description: selection.map((e) => e.name).join(" + "),
        profit: currentTotalProfit,
      ));
    }
  }
}
