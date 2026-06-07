import '../models/investment_option.dart';

class OptimizationResult {
  final InvestmentOption? bank;
  final InvestmentOption? etf;
  final double totalReturn;
  final List<String> trace;

  OptimizationResult({
    this.bank,
    this.etf,
    required this.totalReturn,
    required this.trace,
  });
}

class OptimizerService {
  final List<InvestmentOption> allOptions = [
    InvestmentOption(name: 'GoTyme Bank', annualReturnRate: 0.04, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 500),
    InvestmentOption(name: 'Maya Bank', annualReturnRate: 0.08, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 100),
    InvestmentOption(name: 'CIMB Philippines', annualReturnRate: 0.045, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 50),
    InvestmentOption(name: 'MariBank PH', annualReturnRate: 0.0425, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 50),
    InvestmentOption(name: 'Tonik Digital Bank', annualReturnRate: 0.05, type: InvestmentType.bank, riskLevel: 'Conservative', minInvestment: 500),
    
    InvestmentOption(name: 'VOO', annualReturnRate: 0.125, type: InvestmentType.etf, riskLevel: 'Moderate', minInvestment: 2500),
    InvestmentOption(name: 'VTI', annualReturnRate: 0.12, type: InvestmentType.etf, riskLevel: 'Moderate', minInvestment: 2500),
    InvestmentOption(name: 'QQQ', annualReturnRate: 0.18, type: InvestmentType.etf, riskLevel: 'Aggressive', minInvestment: 5000),
  ];

  OptimizationResult findBestCombo({
    required double capital,
    required String riskAppetite,
    required int months,
  }) {
    List<String> trace = [];
    double maxReturn = -1.0;
    InvestmentOption? bestBank;
    InvestmentOption? bestEtf;

    List<InvestmentOption> banks = allOptions.where((o) => o.type == InvestmentType.bank).toList();
    List<InvestmentOption> etfs = allOptions.where((o) => o.type == InvestmentType.etf).toList();

    for (var bank in banks) {
      for (var etf in etfs) {
        bool isEtfTooRisky = _isTooRisky(etf.riskLevel, riskAppetite);
        double bankAllocation = capital / 2;
        double etfAllocation = capital / 2;
        bool tooExpensive = bankAllocation < bank.minInvestment || etfAllocation < etf.minInvestment;

        if (isEtfTooRisky) {
          trace.add('X Pruned ${bank.name} + ${etf.name} — ETF risk too high for profile');
        } else if (tooExpensive) {
          trace.add('X Pruned ${bank.name} + ${etf.name} — Capital too low for min investment');
        } else {
          double bankReturn = bankAllocation * (bank.annualReturnRate * (months / 12));
          double etfReturn = etfAllocation * (etf.annualReturnRate * (months / 12));
          double totalReturn = bankReturn + etfReturn;

          trace.add('✓ Evaluated ${bank.name} + ${etf.name} ➜ ₱${totalReturn.toStringAsFixed(0)} return');

          if (totalReturn > maxReturn) {
            maxReturn = totalReturn;
            bestBank = bank;
            bestEtf = etf;
          }
        }
      }
    }

    return OptimizationResult(
      bank: bestBank,
      etf: bestEtf,
      totalReturn: maxReturn,
      trace: trace,
    );
  }

  bool _isTooRisky(String optionRisk, String userRisk) {
    if (userRisk == 'Low — conservative') return optionRisk != 'Conservative';
    if (userRisk == 'Medium — balanced') return optionRisk == 'Aggressive';
    return false;
  }
}
