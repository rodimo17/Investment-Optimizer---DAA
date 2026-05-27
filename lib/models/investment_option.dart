enum InvestmentType { bank, etf }

class InvestmentOption {
  final String name;
  final double annualReturnRate;
  final InvestmentType type;
  final String riskLevel;
  final double minInvestment; // The "Weight" in Knapsack

  InvestmentOption({
    required this.name,
    required this.annualReturnRate,
    required this.type,
    required this.riskLevel,
    required this.minInvestment,
  });

  // The "Value" in Knapsack (for a unit of investment)
  double get value => annualReturnRate;
}
