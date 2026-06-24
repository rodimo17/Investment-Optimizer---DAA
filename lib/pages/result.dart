import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'details.dart';
import 'settings.dart';
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
  final _settings = AppSettings();
  late NumberFormat _currencyFormat;
  bool _showSteps = false;

  late Future<List<EtfPriceData>> _etfPricesFuture;

  // ── Currency helpers ──────────────────────────────────────────────────────

  String get _currencySymbol => _settings.currency.split(' ').first;

  void _rebuildCurrencyFormat() {
    final decimals = _settings.decimalPlaces;
    final pattern = decimals == 0 ? '#,##0' : '#,##0.${'0' * decimals}';
    _currencyFormat = NumberFormat(pattern, 'en_US');
  }

  @override
  void initState() {
    super.initState();

    _rebuildCurrencyFormat();
    _settings.addListener(_onSettingsChanged);

    _etfPricesFuture = EtfPriceService().getMonthlyPrices();

    // ── Animate Results setting ───────────────────────────────────────────
    // Only delay the step reveal when animations are enabled.
    if (_settings.animateResults) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _showSteps = true);
      });
    } else {
      _showSteps = true;
    }
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() => _rebuildCurrencyFormat());
    }
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.optimizationResult;
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        const Icon(Icons.psychology,
                            size: 16, color: Colors.indigo),
                        const SizedBox(width: 8),
                        Text(
                          'PURE BACKTRACKING SEARCH',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[400],
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
                      (context, index) =>
                          _buildStepItem(res.steps[index], index),
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
      },
    );
  }

  // ── Sliver header ─────────────────────────────────────────────────────────

  Widget _buildSliverHeader(OptimizationResult? res) {
    final found = res != null && res.allocations.isNotEmpty;
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.indigo[900]!, Colors.deepPurple[800]!],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        padding: const EdgeInsets.only(
            top: 60, bottom: 40, left: 24, right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  found ? 'Strategy Found' : 'No Result',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Profit section ───────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Text(
                  'ESTIMATED PROFIT',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                // ── Display Currency + Decimal Places settings ───────────
                Text(
                  '$_currencySymbol${_currencyFormat.format(res.totalProfit)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 40,
                    letterSpacing: -1,
                    color: Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Display Currency + Decimal Places settings ─────────────────
          _buildStatRow(
            'Committed Capital',
            '$_currencySymbol${_currencyFormat.format(res.usedCapital)}',
            Colors.indigo[400]!,
          ),
          Divider(
              height: 40,
              thickness: 0.5,
              color: Theme.of(context).dividerColor),

          // ── Badges ───────────────────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // ── Show Risk Badge setting ──────────────────────────────────
              if (_settings.showRiskBadge)
                _buildMiniBadge(
                  'RISK ${res.totalRiskScore}/${res.maxRiskLimit}',
                  Icons.shield_rounded,
                  Colors.amber[700]!,
                ),
              if (res.etfAllocationPercent > 0)
                _buildMiniBadge(
                  'ETF ${res.etfAllocationPercent.toStringAsFixed(1)}%',
                  Icons.auto_graph_rounded,
                  Colors.indigo[400]!,
                ),
              if (res.bankAllocationPercent > 0)
                _buildMiniBadge(
                  'BANK ${res.bankAllocationPercent.toStringAsFixed(1)}%',
                  Icons.account_balance_rounded,
                  const Color(0xFF059669),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Allocation header ────────────────────────────────────────────
          Text(
            'TARGET ALLOCATIONS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // ── Allocation rows ──────────────────────────────────────────────
          ...res.allocations.map((alloc) => _buildAllocationRow(alloc)),
          const SizedBox(height: 12),
          _buildDaaStatsMini(res),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAllocationRow(Allocation alloc) {
    final isEtf = alloc.option.type == InvestmentType.etf;
    final accentColor = isEtf ? Colors.indigo : Colors.deepPurple;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isEtf ? Icons.insights : Icons.account_balance,
              size: 20,
              color: accentColor[300],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        // ── Decimal Places setting ───────────────────────
                        '${(alloc.option.annualReturnRate * 100).toStringAsFixed(_settings.decimalPlaces)}% p.a.',
                        style: const TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  // ── Display Currency + Decimal Places settings ─────────
                  '$_currencySymbol${_currencyFormat.format(alloc.amount)} committed',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            // ── Display Currency + Decimal Places settings ───────────────
            '+$_currencySymbol${_currencyFormat.format(alloc.profit)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF059669),
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
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology_outlined, color: Colors.blue[300], size: 20),
          const SizedBox(width: 12),
          Text(
            'States explored: ',
            style: TextStyle(
              color: Colors.blue[300],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${res.statesExplored} iterations',
            style: TextStyle(
              color: Colors.blue[300],
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
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
          Row(
            children: [
              const Icon(Icons.trending_up,
                  color: Colors.deepPurple, size: 18),
              const SizedBox(width: 8),
              Text(
                'ETF Market Pulse',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Live ETF trend data for reference.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
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
                return Text(
                  'ETF prices are unavailable right now.',
                  style: TextStyle(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                );
              }
              return Column(
                children: snapshot.data!.map((price) {
                  final isPositive = price.monthlyChange >= 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              Colors.deepPurple.withOpacity(0.12),
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
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                              Text(
                                price.lastUpdated,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
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
                              // ── Display Currency setting ───────────────
                              '$_currencySymbol${price.currentPrice.toStringAsFixed(_settings.decimalPlaces)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface,
                              ),
                            ),
                            Text(
                              '${isPositive ? '+' : ''}${price.monthlyChange.toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: isPositive
                                    ? const Color(0xFF059669)
                                    : Colors.red[400],
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

  // ── Backtracking trace steps ──────────────────────────────────────────────

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
    }

    final tile = Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: color, size: 18),
        title: Text(
          step.description,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          step.title,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: step.profit != null
            ? Text(
                // ── Display Currency + Decimal Places settings ───────────
                '+$_currencySymbol${_currencyFormat.format(step.profit!)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Color(0xFF059669),
                ),
              )
            : null,
      ),
    );

    // ── Animate Results setting ───────────────────────────────────────────
    // When animations are disabled, render the tile directly with no
    // TweenAnimationBuilder overhead.
    if (!_settings.animateResults) return tile;

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
      child: tile,
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
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor:
            Theme.of(context).colorScheme.onSurfaceVariant,
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