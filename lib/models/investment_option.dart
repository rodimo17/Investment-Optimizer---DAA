enum InvestmentType { bank, etf }

class InvestmentOption {
  final String name;
  final double annualReturnRate; // High/Promo rate
  final double baseReturnRate; // Rate after cap (e.g. 0.035 for Maya)
  final InvestmentType type;
  final String riskLevel;
  final double minInvestment;
  final double? interestCap;
  final int safetyRating;
  final int liquidityScore;

  InvestmentOption({
    required this.name,
    required this.annualReturnRate,
    required this.baseReturnRate,
    required this.type,
    required this.riskLevel,
    required this.minInvestment,
    this.interestCap,
    required this.safetyRating,
    required this.liquidityScore,
  });

  /// Calculates an overall ranking score based on Return, Safety, and Liquidity
  double get overallScore {
    // Weighted formula: 50% Return, 30% Safety, 20% Liquidity
    return (annualReturnRate * 100 * 5.0) + (safetyRating * 3.0) + (liquidityScore * 2.0);
  }
}
