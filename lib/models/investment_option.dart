enum InvestmentType { bank, etf, govt, reit }

class InvestmentOption {
  final String name;
  final double annualReturnRate; 
  final double baseReturnRate; 
  final InvestmentType type;
  final String riskLevel;
  final double minInvestment;
  final double? interestCap;
  final int riskScore; // Unified Risk Index (1-10)

  InvestmentOption({
    required this.name,
    required this.annualReturnRate,
    required this.baseRateAmount, // Keeping field name for compatibility if needed
    required this.baseReturnRate,
    required this.type,
    required this.riskLevel,
    required this.minInvestment,
    this.interestCap,
    required this.riskScore,
  });

  // Re-constructor for easier updates
  InvestmentOption copyWith({double? annualReturnRate}) {
    return InvestmentOption(
      name: name,
      annualReturnRate: annualReturnRate ?? this.annualReturnRate,
      baseReturnRate: baseReturnRate,
      baseRateAmount: 0.0,
      type: type,
      riskLevel: riskLevel,
      minInvestment: minInvestment,
      interestCap: interestCap,
      riskScore: riskScore,
    );
  }

  String get typeLabel {
    switch (type) {
      case InvestmentType.bank: return 'Digital Bank';
      case InvestmentType.etf: return 'Stock ETF';
      case InvestmentType.govt: return 'Govt Bond';
      case InvestmentType.reit: return 'REIT (Property)';
    }
  }

  /// DAA Scoring Logic: Return-to-Risk Ratio
  double get overallScore {
    // Math: Efficiency = (Return * 100) / Risk
    // A high ROI with low risk gives a massive efficiency score.
    return (annualReturnRate * 100) / (riskScore > 0 ? riskScore : 1);
  }
}
