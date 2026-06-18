import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/optimizer_service.dart';
import '../models/investment_option.dart';

class ResultPage extends StatelessWidget {
  final OptimizationResult optimizationResult;
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "en_US");

  ResultPage({super.key, required this.optimizationResult});

  @override
  Widget build(BuildContext context) {
    final res = optimizationResult;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(context),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildTotalProfitCard(res),
                const SizedBox(height: 24),
                _buildAnalyticsSummary(res),
                const SizedBox(height: 24),
                const Text('OPTIMIZED ALLOCATIONS', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                ...res.allocations.map((a) => _buildAllocationItem(a)),
                const SizedBox(height: 24),
                const Text('BACKTRACKING TRACE', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                ...res.steps.map((s) => _buildTraceStep(s)),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: const Color(0xFF4A148C),
      flexibleSpace: const FlexibleSpaceBar(
        title: Text('Strategy Found', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildTotalProfitCard(OptimizationResult res) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20)],
      ),
      child: Column(
        children: [
          const Text('ESTIMATED PROFIT', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('₱${_currencyFormat.format(res.totalProfit)}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSummary(OptimizationResult res) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _analyticRow('Used Capital', '₱${_currencyFormat.format(res.usedCapital)}'),
          _analyticRow('Total Risk', '${res.totalRiskScore} (Max: ${res.maxRiskLimit})'),
          _analyticRow('Bank / ETF Mix', '${res.bankAllocationPercent.toStringAsFixed(0)}% / ${res.etfAllocationPercent.toStringAsFixed(0)}%'),
          _analyticRow('Min Assets Met', res.metDiversificationFloor ? 'YES' : 'NO'),
        ],
      ),
    );
  }

  Widget _analyticRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAllocationItem(Allocation a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(a.option.type == InvestmentType.bank ? Icons.account_balance : Icons.insights, color: Colors.deepPurple),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.option.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Allocation: ₱${_currencyFormat.format(a.amount)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text('+₱${_currencyFormat.format(a.profit)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildTraceStep(TraceStep s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(s.type == StepType.pruned ? Icons.block : Icons.check_circle, size: 16, color: s.type == StepType.pruned ? Colors.red : Colors.blue),
          const SizedBox(width: 12),
          Expanded(child: Text(s.description, style: const TextStyle(fontSize: 10))),
        ],
      ),
    );
  }
}
