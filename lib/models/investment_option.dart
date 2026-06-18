enum InvestmentType { bank, etf, govt, reit }

class InvestmentOption {
  final String name;
  final double annualReturnRate; 
  final double baseReturnRate; 
  final double baseRateAmount; 
  final InvestmentType type;
  final String riskLevel;
  final double minInvestment;
  final double? interestCap;
  final int riskScore;

  InvestmentOption({
    required this.name,
    required this.annualReturnRate,
    required this.baseRateAmount,
    required this.baseReturnRate,
    required this.type,
    required this.riskLevel,
    required this.minInvestment,
    this.interestCap,
    required this.riskScore,
  });

  InvestmentOption copyWith({double? annualReturnRate}) {
    return InvestmentOption(
      name: name,
      annualReturnRate: annualReturnRate ?? this.annualReturnRate,
      baseReturnRate: baseReturnRate,
      baseRateAmount: baseRateAmount,
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

  double get overallScore {
    return (annualReturnRate * 100) / (riskScore > 0 ? riskScore : 1);
  }
}
