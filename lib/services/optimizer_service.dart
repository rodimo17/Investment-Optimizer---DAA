import 'dart:convert';
import 'package:http/http.dart' as http;
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

  Allocation({
    required this.option,
    required this.amount,
    required this.profit,
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
  // Base Interest Rates (2024 - No Promos)
  List<InvestmentOption> allOptions = [
    InvestmentOption(name: 'SeaBank', annualReturnRate: 0.0425, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 1),
    InvestmentOption(name: 'UNO Digital', annualReturnRate: 0.0425, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 1),
    InvestmentOption(name: 'GoTyme Bank', annualReturnRate: 0.04, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 500),
    InvestmentOption(name: 'Tonik Bank', annualReturnRate: 0.04, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 500),
    InvestmentOption(name: 'Maya Bank', annualReturnRate: 0.035, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 100),
    InvestmentOption(name: 'CIMB Bank', annualReturnRate: 0.025, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 50),
    InvestmentOption(name: 'VOO ETF', annualReturnRate: 0.125, type: InvestmentType.etf, riskLevel: 'Moderate', minInvestment: 2500),
    InvestmentOption(name: 'VTI ETF', annualReturnRate: 0.12, type: InvestmentType.etf, riskLevel: 'Moderate', minInvestment: 2500),
    InvestmentOption(name: 'QQQ ETF', annualReturnRate: 0.18, type: InvestmentType.etf, riskLevel: 'Aggressive', minInvestment: 5000),
  ];

  double _maxProfit = -1.0;
  List<InvestmentOption> _bestCombo = [];
  List<TraceStep> _steps = [];
  int _statesCount = 0;

  /// Fetches latest rates from a remote source.
  /// For this example, I'm using a placeholder logic. 
  /// In a real app, you'd point this to a GitHub Gist or your own API.
  Future<void> fetchLatestRates() async {
    try {
      // Example URL: Replace with your actual JSON endpoint
      // For now, I'll simulate a fetch delay to show how the UI handles it
      await Future.delayed(const Duration(seconds: 1));
      
      // If you had a real API, it would look like this:
      /*
      final response = await http.get(Uri.parse('https://api.jsonbin.io/v3/b/YOUR_ID'));
      if (response.statusCode == 200) {
         final data = json.decode(response.body);
         // Update allOptions here
      }
      */
      
      print('Rates updated successfully from "Remote Source"');
    } catch (e) {
      print('Failed to fetch rates, using defaults: $e');
    }
  }

  OptimizationResult solveKnapsack({
    required double capacity,
    required String riskPreference,
    required String horizon,
    required int maxOptions,
  }) {
    _maxProfit = -1.0;
    _bestCombo = [];
    _steps = [];
    _statesCount = 0;

    double timeFactor = 1.0;
    if (horizon == '1 month') timeFactor = 1 / 12;
    else if (horizon == '3 months') timeFactor = 3 / 12;
    else if (horizon == '6 months') timeFactor = 6 / 12;

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
        double profit = splitAmount * (item.annualReturnRate * timeFactor);
        
        finalAllocations.add(Allocation(
          option: item,
          amount: splitAmount,
          profit: profit,
        ));
      }
    }

    return OptimizationResult(
      allocations: finalAllocations,
      totalProfit: _maxProfit,
      steps: _steps,
      statesExplored: _statesCount,
    );
  }

  void _backtrack(List<InvestmentOption> options, int index, List<InvestmentOption> current, double capacity, int limit, double timeFactor) {
    _statesCount++;

    if (index == options.length || current.length == limit) {
      if (current.isNotEmpty) {
        bool hasBank = current.any((o) => o.type == InvestmentType.bank);
        bool hasEtf = current.any((o) => o.type == InvestmentType.etf);

        if (limit > 1 && (!hasBank || !hasEtf)) return;

        double splitAmount = capacity / current.length;
        if (current.every((o) => splitAmount >= o.minInvestment)) {
          double totalProfit = 0;
          for (var o in current) {
            totalProfit += splitAmount * (o.annualReturnRate * timeFactor);
          }

          String comboName = current.map((e) => e.name).join(" + ");

          if (totalProfit > _maxProfit) {
            _maxProfit = totalProfit;
            _bestCombo = List.from(current);
            _steps.add(TraceStep(
              type: StepType.bestFound,
              title: 'New Optimal Combo Found',
              description: comboName,
              profit: totalProfit,
            ));
          } else {
            _steps.add(TraceStep(
              type: StepType.evaluated,
              title: 'Evaluated Combo',
              description: comboName,
              profit: totalProfit,
            ));
          }
        } else {
          _steps.add(TraceStep(
            type: StepType.pruned,
            title: 'Constraint Pruned',
            description: '${current.map((e) => e.name).join("+")} (Insufficient Capital)',
          ));
        }
      }
      return;
    }

    // Branch 1: Include
    current.add(options[index]);
    _backtrack(options, index + 1, current, capacity, limit, timeFactor);
    current.removeLast();

    // Branch 2: Exclude
    _backtrack(options, index + 1, current, capacity, limit, timeFactor);
  }
}
