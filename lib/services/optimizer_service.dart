import 'dart:math';
import '../models/investment_option.dart';
import 'etf_price_service.dart';

enum StepType { evaluated, pruned, bestFound, backtrackInfo }

class TraceStep {
  final StepType type;
  final String title;
  final String description;
  final double? profit;

  TraceStep({required this.type, required this.title, required this.description, this.profit});
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

  Allocation({required this.option, required this.amount, required this.highRateAmount, required this.baseRateAmount, required this.highRateProfit, required this.baseRateProfit, required this.profit, required this.rank});
}

class OptimizationResult {
  final List<Allocation> allocations;
  final double totalProfit;
  final List<TraceStep> steps;
  final int statesExplored;

  OptimizationResult({required this.allocations, required this.totalProfit, required this.steps, required this.statesExplored});
}

class OptimizerService {
  static final OptimizerService _instance = OptimizerService._internal();
  factory OptimizerService() => _instance;
  OptimizerService._internal();

  final List<InvestmentOption> allOptions = [
    InvestmentOption(name: 'Maya Bank', annualReturnRate: 0.10, baseReturnRate: 0.035, baseRateAmount: 0, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 100, interestCap: 100000, riskScore: 2),
    InvestmentOption(name: 'SeaBank', annualReturnRate: 0.0425, baseReturnRate: 0.03, baseRateAmount: 0, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 1, interestCap: 400000, riskScore: 1),
    InvestmentOption(name: 'UNO Digital', annualReturnRate: 0.0425, baseReturnRate: 0.035, baseRateAmount: 0, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 1, interestCap: 500000, riskScore: 3),
    InvestmentOption(name: 'GoTyme Bank', annualReturnRate: 0.04, baseReturnRate: 0.04, baseRateAmount: 0, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 500, riskScore: 1),
    InvestmentOption(name: 'Tonik Bank', annualReturnRate: 0.04, baseReturnRate: 0.04, baseRateAmount: 0, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 500, riskScore: 2),
    InvestmentOption(name: 'CIMB Bank', annualReturnRate: 0.025, baseReturnRate: 0.025, baseRateAmount: 0, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 50, riskScore: 1),
    InvestmentOption(name: 'VOO ETF', annualReturnRate: 0.125, baseReturnRate: 0.125, baseRateAmount: 0, type: InvestmentType.etf, riskLevel: 'Moderate', minInvestment: 2500, riskScore: 7),
    InvestmentOption(name: 'VTI ETF', annualReturnRate: 0.12, baseReturnRate: 0.12, baseRateAmount: 0, type: InvestmentType.etf, riskLevel: 'Moderate', minInvestment: 2500, riskScore: 7),
    InvestmentOption(name: 'QQQ ETF', annualReturnRate: 0.18, baseReturnRate: 0.18, baseRateAmount: 0, type: InvestmentType.etf, riskLevel: 'Aggressive', minInvestment: 5000, riskScore: 9),
  ];

  double _maxProfit = -1.0;
  List<Allocation> _bestAllocations = [];
  List<TraceStep> _steps = [];
  int _statesCount = 0;

  Future<void> fetchLatestRates() async {
    final etfService = EtfPriceService();
    final realTimeEtfs = await etfService.fetchRealTimePrices();
    await Future.delayed(const Duration(milliseconds: 500));
    final random = Random();
    for (var i = 0; i < allOptions.length; i++) {
      double newRate = allOptions[i].annualReturnRate;
      if (allOptions[i].type == InvestmentType.etf) {
        final match = realTimeEtfs.where((e) => allOptions[i].name.contains(e.ticker)).firstOrNull;
        if (match != null) newRate = (allOptions[i].annualReturnRate + (match.monthlyChange / 100)).clamp(0.05, 0.30);
      } else {
        newRate = (allOptions[i].annualReturnRate + ((random.nextDouble() * 0.002) - 0.001)).clamp(0.01, 0.15);
      }
      allOptions[i] = allOptions[i].copyWith(annualReturnRate: newRate);
    }
  }

  OptimizationResult solveKnapsack({required double capacity, required String riskPreference, required String horizon, required int maxOptions, required List<double> userSplits}) {
    _maxProfit = -1.0; _bestAllocations = []; _steps = []; _statesCount = 0;
    double timeFactor = horizon == '1 month' ? 1/12 : (horizon == '3 months' ? 3/12 : (horizon == '6 months' ? 6/12 : 1.0));

    // 1. DAA PRE-FILTERING (Constraint Satisfaction)
    int maxAllowedRisk = riskPreference == 'Conservative' ? 3 : (riskPreference == 'Moderate' ? 7 : 10);
    List<InvestmentOption> available = allOptions.where((opt) => opt.riskScore <= maxAllowedRisk).toList();
    
    // Sort by efficiency (DAA Trick: ROI/Risk)
    available.sort((a, b) => b.overallScore.compareTo(a.overallScore));
    List<double> sortedSplits = [...userSplits]..sort((a, b) => b.compareTo(a));

    _backtrack(available, 0, [], capacity, maxOptions, timeFactor, sortedSplits);

    return OptimizationResult(allocations: _bestAllocations, totalProfit: _maxProfit, steps: _steps, statesExplored: _statesCount);
  }

  void _backtrack(List<InvestmentOption> options, int index, List<InvestmentOption> current, double capacity, int limit, double timeFactor, List<double> splits) {
    _statesCount++;
    if (current.length == limit || index == options.length) {
      if (current.isNotEmpty) _evaluateUserSplit(current, capacity, timeFactor, splits);
      return;
    }
    // Path 1: Include
    if (current.length < limit) {
      current.add(options[index]);
      _backtrack(options, index + 1, current, capacity, limit, timeFactor, splits);
      current.removeLast();
    }
    // Path 2: Exclude
    _backtrack(options, index + 1, current, capacity, limit, timeFactor, splits);
  }

  void _evaluateUserSplit(List<InvestmentOption> selection, double totalCapacity, double timeFactor, List<double> splits) {
    List<InvestmentOption> ranked = [...selection]..sort((a, b) => b.annualReturnRate.compareTo(a.annualReturnRate));
    double totalP = 0; List<Allocation> currentAllocs = [];
    for (int i = 0; i < ranked.length; i++) {
      double amount = totalCapacity * (i < splits.length ? splits[i] : 0.0);
      if (amount < ranked[i].minInvestment) return;
      double high = ranked[i].interestCap != null ? amount.clamp(0, ranked[i].interestCap!) : amount;
      double profit = (high * ranked[i].annualReturnRate + (amount - high) * ranked[i].baseReturnRate) * timeFactor;
      totalP += profit;
      currentAllocs.add(Allocation(option: ranked[i], amount: amount, highRateAmount: high, baseRateAmount: (amount - high), highRateProfit: high * ranked[i].annualReturnRate * timeFactor, baseRateProfit: (amount - high) * ranked[i].baseReturnRate * timeFactor, profit: profit, rank: i + 1));
    }
    if (totalP > _maxProfit) {
      _maxProfit = totalP; _bestAllocations = currentAllocs;
      _steps.add(TraceStep(type: StepType.bestFound, title: 'Optimized Set Found', description: selection.map((e) => e.name).join(" + "), profit: totalP));
    }
  }
}
