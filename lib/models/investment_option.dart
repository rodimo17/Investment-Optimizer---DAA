enum InvestmentType { bank, etf, govt, reit }

class InvestmentOption {
  final String name;
  final double annualReturnRate;
  final InvestmentType type;
  final String riskLevel;
  final int riskScore;
  final double minInvestment;
  final double depositAmount;

  InvestmentOption({
    required this.name,
    required this.annualReturnRate,
    required this.type,
    required this.riskLevel,
    required this.riskScore,
    required this.minInvestment,
    this.depositAmount = 0.0,
  });

  InvestmentOption copyWith({
    double? annualReturnRate,
    double? depositAmount,
    int? riskScore,
  }) {
    return InvestmentOption(
      name: name,
      annualReturnRate: annualReturnRate ?? this.annualReturnRate,
      type: type,
      riskLevel: riskLevel,
      riskScore: riskScore ?? this.riskScore,
      minInvestment: minInvestment,
      depositAmount: depositAmount ?? this.depositAmount,
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
