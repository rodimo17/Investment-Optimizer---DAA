import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'details.dart';
import '../services/etf_price_service.dart';
import '../services/optimizer_service.dart';
import '../models/investment_option.dart';

class ResultPage extends StatefulWidget {
  final OptimizationResult? optimizationResult;

  const ResultPage({super.key, this.optimizationResult});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "en_US");
  bool _showSteps = false;

  late Future<List<EtfPriceData>> _etfPricesFuture;

  @override
  void initState() {
    super.initState();
    _etfPricesFuture = EtfPriceService().getMonthlyPrices();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showSteps = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.optimizationResult;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: _buildBottomNav(context),
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(res),
          if (res == null || res.allocations.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No valid combinations found.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Try increasing your capital, adjusting your risk tolerance, '
                        'or lowering some deposit amounts.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(child: _buildMainStatsCard(res)),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(child: _buildEtfPulseCard()),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Icon(Icons.psychology, size: 16, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text(
                      'PURE BACKTRACKING SEARCH',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showSteps)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildStepItem(res.steps[index], index),
                  childCount: res.steps.length,
                ),
              )
            else
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ],
      ),
    );
  }

  // ── Sliver header ─────────────────────────────────────────────────────────

  Widget _buildSliverHeader(OptimizationResult? res) {
    final found = res != null && res.allocations.isNotEmpty;
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.deepPurple,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.only(top: 60, bottom: 40, left: 24, right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  found ? 'Optimal Strategy' : 'No Result',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                found
                    ? '${res.allocations.length} OPTION${res.allocations.length > 1 ? 'S' : ''} · GLOBAL OPTIMUM ACHIEVED'
                    : 'ADJUST INPUTS AND TRY AGAIN',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main stats card ───────────────────────────────────────────────────────

  Widget _buildMainStatsCard(OptimizationResult res) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profit row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimated Profit',
                style: TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              Text(
                '₱${_currencyFormat.format(res.totalProfit)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Committed capital row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Committed Capital',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              Text(
                '₱${_currencyFormat.format(res.usedCapital)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const Divider(height: 32),

          // Badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMiniBadge(
                'Risk ${res.totalRiskScore.toStringAsFixed(0)}/${res.maxRiskLimit}',
                Icons.shield,
                Colors.blue,
              ),
              if (res.etfAllocationPercent > 0)
                _buildMiniBadge(
                  'ETF ${res.etfAllocationPercent.toStringAsFixed(0)}%',
                  Icons.insights,
                  Colors.indigo,
                ),
              if (res.bankAllocationPercent > 0)
                _buildMiniBadge(
                  'Bank ${res.bankAllocationPercent.toStringAsFixed(0)}%',
                  Icons.account_balance,
                  Colors.green,
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Allocation rows
          ...res.allocations.map((alloc) => _buildAllocationRow(alloc)),
          const SizedBox(height: 12),
          _buildDaaStatsMini(res),
        ],
      ),
    );
  }

  Widget _buildAllocationRow(Allocation alloc) {
    final isEtf = alloc.option.type == InvestmentType.etf;
    final accentColor = isEtf ? Colors.indigo : Colors.deepPurple;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Type icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isEtf ? Icons.insights : Icons.account_balance,
              size: 20,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 14),
          // Name + details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Rank badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${alloc.rank}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        alloc.option.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Rate badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${(alloc.option.annualReturnRate * 100).toStringAsFixed(2)}% p.a.',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Committed amount — framed as user's commitment, not algo output
                Text(
                  '₱${_currencyFormat.format(alloc.amount)} committed',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Profit
          Text(
            '+₱${_currencyFormat.format(alloc.profit)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaaStatsMini(OptimizationResult res) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology_outlined, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          const Text(
            'States explored: ',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${res.statesExplored} iterations',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── ETF pulse card ────────────────────────────────────────────────────────

  Widget _buildEtfPulseCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.deepPurple, size: 18),
              SizedBox(width: 8),
              Text(
                'ETF Market Pulse',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Live ETF trend data for reference.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<EtfPriceData>>(
            future: _etfPricesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text(
                  'ETF prices are unavailable right now.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                );
              }
              return Column(
                children: snapshot.data!.map((price) {
                  final isPositive = price.monthlyChange >= 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.deepPurple[50],
                          child: Text(
                            price.ticker[0],
                            style: const TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                price.ticker,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                price.lastUpdated,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₱${price.currentPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${isPositive ? '+' : ''}${price.monthlyChange.toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: isPositive ? Colors.green : Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Backtracking trace steps ───────────────────────────────────────────────

  Widget _buildStepItem(TraceStep step, int index) {
    IconData icon;
    Color color;
    switch (step.type) {
      case StepType.bestFound:
        icon = Icons.auto_awesome;
        color = Colors.orange;
        break;
      case StepType.evaluated:
        icon = Icons.search;
        color = Colors.blue;
        break;
      case StepType.pruned:
        icon = Icons.block;
        color = Colors.grey;
        break;
      case StepType.backtrackInfo:
        icon = Icons.account_tree_outlined;
        color = Colors.teal;
        break;
    }

    return TweenAnimationBuilder(
      duration: Duration(
        milliseconds: 300 + (index * 50).clamp(0, 1000).toInt(),
      ),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          dense: true,
          leading: Icon(icon, color: color, size: 18),
          title: Text(
            step.description,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            step.title,
            style: const TextStyle(fontSize: 10),
          ),
          trailing: step.profit != null
              ? Text(
                  '+₱${_currencyFormat.format(step.profit!)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.green,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  // ── Bottom nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DetailsPage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: 'Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'Details',
          ),
        ],
      ),
    );
  }
}