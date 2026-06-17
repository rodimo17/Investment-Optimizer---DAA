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
  static final OptimizerService _instance = OptimizerService._internal();
  factory OptimizerService() => _instance;
  OptimizerService._internal();

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
    required List<double> userSplits,
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
    
    // Ensure splits are sorted descending so highest % goes to best asset
    List<double> sortedSplits = [...userSplits]..sort((a, b) => b.compareTo(a));

    _backtrack(available, 0, [], capacity, maxOptions, timeFactor, sortedSplits);

    return OptimizationResult(
      allocations: _bestAllocations,
      totalProfit: _maxProfit,
      steps: _steps,
      statesExplored: _statesCount,
      branchesPruned: _prunedCount,
    );
  }

  void _backtrack(List<InvestmentOption> options, int index, List<InvestmentOption> current, double capacity, int limit, double timeFactor, List<double> splits) {
    _statesCount++;

    if (current.length == limit || index == options.length) {
      if (current.isNotEmpty) {
        _evaluateUserSplit(current, capacity, timeFactor, splits);
      }
      return;
    }

    // Include
    if (current.length < limit) {
      current.add(options[index]);
      _backtrack(options, index + 1, current, capacity, limit, timeFactor, splits);
      current.removeLast();
    }

    // Exclude
    _backtrack(options, index + 1, current, capacity, limit, timeFactor, splits);
  }

  void _evaluateUserSplit(List<InvestmentOption> selection, double totalCapacity, double timeFactor, List<double> splits) {
    // Sort selection by return rate to match with descending splits
    List<InvestmentOption> rankedSelection = [...selection];
    rankedSelection.sort((a, b) => b.annualReturnRate.compareTo(a.annualReturnRate));

    double currentTotalProfit = 0;
    List<Allocation> currentAllocations = [];

    for (int i = 0; i < rankedSelection.length; i++) {
      var option = rankedSelection[i];
      double splitPercent = i < splits.length ? splits[i] : 0.0;
      double amount = totalCapacity * splitPercent;

      if (amount < option.minInvestment) return;

      double highRateAmount = 0;
      double baseRateAmount = 0;
      double highRateProfit = 0;
      double baseRateProfit = 0;

      if (option.interestCap != null) {
        highRateAmount = amount.clamp(0, option.interestCap!);
        baseRateAmount = (amount - highRateAmount).clamp(0, double.infinity);
        highRateProfit = (highRateAmount * option.annualReturnRate) * timeFactor;
        baseRateProfit = (baseRateAmount * option.baseReturnRate) * timeFactor;
      } else {
        highRateAmount = amount;
        highRateProfit = (amount * option.annualReturnRate) * timeFactor;
      }

      double totalProfit = highRateProfit + baseRateProfit;
      currentTotalProfit += totalProfit;

      currentAllocations.add(Allocation(
        option: option,
        amount: amount,
        highRateAmount: highRateAmount,
        baseRateAmount: baseRateAmount,
        highRateProfit: highRateProfit,
        baseRateProfit: baseRateProfit,
        profit: totalProfit,
        rank: i + 1,
      ));
    }

    if (currentTotalProfit > _maxProfit) {
      _maxProfit = currentTotalProfit;
      _bestAllocations = currentAllocations;

      _steps.add(TraceStep(
        type: StepType.bestFound,
        title: 'New Strategy Found with Your Splits',
        description: selection.map((e) => e.name).join(" + "),
        profit: currentTotalProfit,
      ));
    }
  }
}
