enum InvestmentType { bank, etf }

class InvestmentOption {
  final String name;
  final double annualReturnRate; // High/Promo rate
  final double baseReturnRate; // Rate after cap (e.g. 0.035 for Maya)
  final InvestmentType type;
  final String riskLevel;
  final double minInvestment;

  InvestmentOption({
    required this.name,
    required this.annualReturnRate,
    required this.baseReturnRate,
    required this.type,
    required this.riskLevel,
    required this.minInvestment,
  });

  String get typeLabel {
    switch (type) {
      case InvestmentType.bank: return 'Digital Bank';
      case InvestmentType.etf: return 'Stock ETF';
    }
  }
}
