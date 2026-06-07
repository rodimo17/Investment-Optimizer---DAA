import '../models/investment_option.dart';

class OptimizationResult {
  final InvestmentOption? bank;
  final InvestmentOption? etf;
  final double totalReturn;
  final double returnPercentage;
  final List<String> trace;

  OptimizationResult({
    this.bank,
    this.etf,
    required this.totalReturn,
    required this.returnPercentage,
    required this.trace,
  });
}

class OptimizerService {
  final List<InvestmentOption> banks = [
    InvestmentOption(name: 'GoTyme Bank', annualReturnRate: 0.04, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 500),
    InvestmentOption(name: 'Maya Bank', annualReturnRate: 0.08, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 100),
    InvestmentOption(name: 'CIMB Philippines', annualReturnRate: 0.045, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 50),
    InvestmentOption(name: 'MariBank PH', annualReturnRate: 0.0425, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 50),
    InvestmentOption(name: 'Tonik Digital Bank', annualReturnRate: 0.05, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 500),
  ];

  final List<InvestmentOption> etfs = [
    InvestmentOption(name: 'VOO', annualReturnRate: 0.125, type: InvestmentType.etf, riskLevel: 'Moderate', minInvestment: 2500),
    InvestmentOption(name: 'VTI', annualReturnRate: 0.12, type: InvestmentType.etf, riskLevel: 'Moderate', minInvestment: 2500),
    InvestmentOption(name: 'QQQ', annualReturnRate: 0.18, type: InvestmentType.etf, riskLevel: 'Aggressive', minInvestment: 5000),
  ];

  List<String> _trace = [];
  double _maxReturn = -1.0;
  InvestmentOption? _bestBank;
  InvestmentOption? _bestEtf;

  OptimizationResult findBestCombo({
    required double capital,
    required String riskAppetite,
    required int months,
  }) {
    _trace = [];
    _maxReturn = -1.0;
    _bestBank = null;
    _bestEtf = null;

    _backtrack(0, capital, riskAppetite, months);

    return OptimizationResult(
      bank: _bestBank,
      etf: _bestEtf,
      totalReturn: _maxReturn,
      returnPercentage: (capital > 0) ? (_maxReturn / capital) * 100 : 0,
      trace: _trace,
    );
  }

  void _backtrack(int bankIdx, double capital, String riskAppetite, int months) {
    if (bankIdx >= banks.length) {
      return;
    }

    InvestmentOption bank = banks[bankIdx];
    double bankAllocation = capital / 2;
    
    for (var etf in etfs) {
      double etfAllocation = capital / 2;
      bool isEtfTooRisky = _isTooRisky(etf.riskLevel, riskAppetite);
      bool tooExpensive = bankAllocation < bank.minInvestment || etfAllocation < etf.minInvestment;
      
      if (isEtfTooRisky) {
        _trace.add('X Pruned ${bank.name} + ${etf.name} — ETF risk too high for profile');
      } else if (tooExpensive) {
        _trace.add('X Pruned ${bank.name} + ${etf.name} — Capital too low for minimum investment');
      } else {
        double bankReturn = bankAllocation * (bank.annualReturnRate * (months / 12));
        double etfReturn = etfAllocation * (etf.annualReturnRate * (months / 12));
        double totalReturn = bankReturn + etfReturn;
        double score = (totalReturn / capital) * 100;

        _trace.add('✓ Evaluated ${bank.name} + ${etf.name} ➜ ₱${totalReturn.toStringAsFixed(0)} return');

        if (totalReturn > _maxReturn) {
          _maxReturn = totalReturn;
          _bestBank = bank;
          _bestEtf = etf;
        }
      }
    }

    _backtrack(bankIdx + 1, capital, riskAppetite, months);
  }

  bool _isTooRisky(String optionRisk, String userRisk) {
    if (userRisk == 'Low — conservative') {
      return optionRisk != 'Conservative';
    } else if (userRisk == 'Medium — balanced') {
      return optionRisk == 'Aggressive';
    }
    return false; // High risk can take anything
  }
}
