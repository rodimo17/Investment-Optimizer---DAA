import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_projects/services/optimizer_service.dart';
import 'package:flutter_projects/models/investment_option.dart';
import 'package:flutter_projects/services/etf_price_service.dart';

void main() {
  group('OptimizerService Tests', () {
    late OptimizerService service;

    setUp(() {
      service = OptimizerService();
    });

    test('updateEtfRates updates rates correctly', () {
      final mockData = [
        EtfPriceData(
          ticker: 'QQQ',
          currentPrice: 100,
          monthlyChange: 2.0, // 2% month = 24% year
          lastUpdated: 'Test',
          history: [],
        ),
      ];

      service.updateEtfRates(mockData);
      
      final qqq = service.allOptions.firstWhere((o) => o.name.contains('QQQ'));
      expect(qqq.annualReturnRate, closeTo(0.24, 0.0001));
    });

    test('solveKnapsack handles double precision', () {
      final customOptions = [
        InvestmentOption(
          name: 'Test Bank',
          annualReturnRate: 0.1,
          type: InvestmentType.bank,
          riskLevel: 'Conservative',
          riskScore: 1,
          minInvestment: 100,
          depositAmount: 500.50,
        ),
      ];

      final result = service.solveKnapsack(
        capacity: 1000,
        riskPreference: 'Conservative',
        horizon: '1 year',
        minOptions: 1,
        customOptions: customOptions,
      );

      expect(result.allocations.length, 1);
      expect(result.allocations.first.amount, 500.50);
      expect(result.totalProfit, closeTo(50.05, 0.001));
    });

    test('generateDefaultDeposits uses double precision', () {
      final options = [
        InvestmentOption(name: 'A', annualReturnRate: 0.1, type: InvestmentType.bank, riskLevel: 'C', riskScore: 1, minInvestment: 1, depositAmount: 0),
      ];
      
      final updated = service.generateDefaultDeposits(options: options, capacity: 100, targetCount: 1);
      expect(updated.first.depositAmount, 100.0);
    });
  });
}
