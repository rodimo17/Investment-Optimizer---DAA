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
}
