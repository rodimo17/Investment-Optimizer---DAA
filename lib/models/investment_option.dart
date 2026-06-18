enum InvestmentType { bank, etf }

class InvestmentOption {
  final String name;
  final double annualReturnRate; // High/Promo rate
  final InvestmentType type;
  final String riskLevel;
  final int riskScore;
  final double minInvestment;
  final int depositAmount;


  InvestmentOption({
    required this.name,
    required this.annualReturnRate,
    required this.type,
    required this.riskLevel,
    required this.riskScore,
    required this.minInvestment,
    required this.depositAmount,
  });

  InvestmentOption copyWith({
    String? name,
    double? annualReturnRate,
    InvestmentType? type,
    String? riskLevel,
    int? riskScore,
    double? minInvestment,
    int? depositAmount,
  }) {
    return InvestmentOption(
      name: name ?? this.name,
      annualReturnRate: annualReturnRate ?? this.annualReturnRate,
      type: type ?? this.type,
      riskLevel: riskLevel ?? this.riskLevel,
      riskScore: riskScore ?? this.riskScore,
      minInvestment: minInvestment ?? this.minInvestment,
      depositAmount: depositAmount ?? this.depositAmount,
    );
  }
}
