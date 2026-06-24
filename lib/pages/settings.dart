import 'package:flutter/material.dart';

/// Persists user preferences so other pages can read them.
/// In a real app you'd use shared_preferences or a state-management solution.
class AppSettings extends ChangeNotifier {
  static final AppSettings _instance = AppSettings._();
  factory AppSettings() => _instance;
  AppSettings._();

  bool _darkMode = false;
  bool _showRiskBadge = true;
  bool _animateResults = true;
  bool _autoRefreshRates = false;
  String _currency = '₱ PHP';
  String _defaultRisk = 'Moderate';
  String _defaultHorizon = '1 month';
  int _decimalPlaces = 2;

  bool get darkMode => _darkMode;
  bool get showRiskBadge => _showRiskBadge;
  bool get animateResults => _animateResults;
  bool get autoRefreshRates => _autoRefreshRates;
  String get currency => _currency;
  String get defaultRisk => _defaultRisk;
  String get defaultHorizon => _defaultHorizon;
  int get decimalPlaces => _decimalPlaces;

  void setDarkMode(bool v) { _darkMode = v; notifyListeners(); }
  void setShowRiskBadge(bool v) { _showRiskBadge = v; notifyListeners(); }
  void setAnimateResults(bool v) { _animateResults = v; notifyListeners(); }
  void setAutoRefreshRates(bool v) { _autoRefreshRates = v; notifyListeners(); }
  void setCurrency(String v) { _currency = v; notifyListeners(); }
  void setDefaultRisk(String v) { _defaultRisk = v; notifyListeners(); }
  void setDefaultHorizon(String v) { _defaultHorizon = v; notifyListeners(); }
  void setDecimalPlaces(int v) { _decimalPlaces = v; notifyListeners(); }

  void resetAll() {
    _darkMode = false;
    _showRiskBadge = true;
    _animateResults = true;
    _autoRefreshRates = false;
    _currency = '₱ PHP';
    _defaultRisk = 'Moderate';
    _defaultHorizon = '1 month';
    _decimalPlaces = 2;
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settings = AppSettings();

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final isDark = _settings.darkMode;
        final bg      = Theme.of(context).scaffoldBackgroundColor;
        final surface = Theme.of(context).cardColor;
        final border  = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
        final textPrimary = Theme.of(context).colorScheme.onSurface;
        final textSub = Theme.of(context).colorScheme.onSurfaceVariant;

        return Scaffold(
          backgroundColor: bg,
          body: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Appearance ──────────────────────────────────────
                      _sectionLabel('APPEARANCE', textSub),
                      const SizedBox(height: 10),
                      _card(surface, border, children: [
                        _toggle(
                          icon: Icons.dark_mode_outlined,
                          label: 'Dark Mode',
                          subtitle: 'Switch to a darker colour scheme',
                          value: _settings.darkMode,
                          onChanged: _settings.setDarkMode,
                          surface: surface,
                          textPrimary: textPrimary,
                          textSub: textSub,
                        ),
                        _divider(border),
                        _toggle(
                          icon: Icons.shield_outlined,
                          label: 'Show Risk Badge',
                          subtitle: 'Display MAX RISK label on the strategy card',
                          value: _settings.showRiskBadge,
                          onChanged: _settings.setShowRiskBadge,
                          surface: surface,
                          textPrimary: textPrimary,
                          textSub: textSub,
                        ),
                        _divider(border),
                        _toggle(
                          icon: Icons.animation_outlined,
                          label: 'Animate Results',
                          subtitle: 'Fade-in transition when results load',
                          value: _settings.animateResults,
                          onChanged: _settings.setAnimateResults,
                          surface: surface,
                          textPrimary: textPrimary,
                          textSub: textSub,
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // ── Data & Rates ────────────────────────────────────
                      _sectionLabel('DATA & RATES', textSub),
                      const SizedBox(height: 10),
                      _card(surface, border, children: [
                        _toggle(
                          icon: Icons.sync_outlined,
                          label: 'Auto-Refresh Rates',
                          subtitle: 'Fetch live ETF prices on every app launch',
                          value: _settings.autoRefreshRates,
                          onChanged: _settings.setAutoRefreshRates,
                          surface: surface,
                          textPrimary: textPrimary,
                          textSub: textSub,
                        ),
                        _divider(border),
                        _dropdown<String>(
                          icon: Icons.monetization_on_outlined,
                          label: 'Display Currency',
                          subtitle: 'Symbol shown in results and inputs',
                          value: _settings.currency,
                          items: const ['₱ PHP', '\$ USD', '€ EUR', '¥ JPY'],
                          onChanged: (v) => _settings.setCurrency(v!),
                          surface: surface,
                          textPrimary: textPrimary,
                          textSub: textSub,
                          border: border,
                        ),
                        _divider(border),
                        _dropdown<int>(
                          icon: Icons.numbers_outlined,
                          label: 'Decimal Places',
                          subtitle: 'Precision shown in monetary values',
                          value: _settings.decimalPlaces,
                          items: const [0, 1, 2, 3, 4],
                          itemLabels: const ['0', '1', '2', '3', '4'],
                          onChanged: (v) => _settings.setDecimalPlaces(v!),
                          surface: surface,
                          textPrimary: textPrimary,
                          textSub: textSub,
                          border: border,
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // ── Optimizer Defaults ──────────────────────────────
                      _sectionLabel('OPTIMIZER DEFAULTS', textSub),
                      const SizedBox(height: 10),
                      _card(surface, border, children: [
                        _dropdown<String>(
                          icon: Icons.shield_outlined,
                          label: 'Default Risk Tolerance',
                          subtitle: 'Pre-selected when the app opens',
                          value: _settings.defaultRisk,
                          items: const ['Conservative', 'Moderate', 'Aggressive'],
                          onChanged: (v) => _settings.setDefaultRisk(v!),
                          surface: surface,
                          textPrimary: textPrimary,
                          textSub: textSub,
                          border: border,
                        ),
                        _divider(border),
                        _dropdown<String>(
                          icon: Icons.calendar_today_outlined,
                          label: 'Default Time Horizon',
                          subtitle: 'Pre-selected investment period',
                          value: _settings.defaultHorizon,
                          items: const ['1 month', '3 months', '6 months', '1 year'],
                          onChanged: (v) => _settings.setDefaultHorizon(v!),
                          surface: surface,
                          textPrimary: textPrimary,
                          textSub: textSub,
                          border: border,
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // ── About ───────────────────────────────────────────
                      _sectionLabel('ABOUT', textSub),
                      const SizedBox(height: 10),
                      _card(surface, border, children: [
                        _infoRow(
                          icon: Icons.info_outline,
                          label: 'Version',
                          value: '1.0.0',
                          textPrimary: textPrimary,
                          textSub: textSub,
                        ),
                        _divider(border),
                        _infoRow(
                          icon: Icons.code,
                          label: 'Algorithm',
                          value: 'Backtracking 0/1 Knapsack',
                          textPrimary: textPrimary,
                          textSub: textSub,
                        ),
                        _divider(border),
                        _infoRow(
                          icon: Icons.school_outlined,
                          label: 'Built for',
                          value: 'Design & Analysis of Algorithms',
                          textPrimary: textPrimary,
                          textSub: textSub,
                        ),
                        _divider(border),
                        _infoRow(
                          icon: Icons.source_outlined,
                          label: 'ETF Data',
                          value: 'Alpha Vantage API',
                          textPrimary: textPrimary,
                          textSub: textSub,
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // ── Reset ───────────────────────────────────────────
                      _resetButton(textSub),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Container(
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
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 60, bottom: 36, left: 24, right: 24),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Investi-Aid preferences',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Card wrapper ──────────────────────────────────────────────────────────

  Widget _card(Color surface, Color border, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(Color border) =>
      Divider(height: 1, thickness: 1, color: border, indent: 60);

  // ── Toggle row ────────────────────────────────────────────────────────────

  Widget _toggle({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color surface,
    required Color textPrimary,
    required Color textSub,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.indigo.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.indigo[700], size: 18),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: textSub),
      ),
      activeColor: Colors.deepPurple,
      value: value,
      onChanged: onChanged,
    );
  }

  // ── Dropdown row ──────────────────────────────────────────────────────────

  Widget _dropdown<T>({
    required IconData icon,
    required String label,
    required String subtitle,
    required T value,
    required List<T> items,
    List<String>? itemLabels,
    required ValueChanged<T?> onChanged,
    required Color surface,
    required Color textPrimary,
    required Color textSub,
    required Color border,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.indigo[700], size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: textSub)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: DropdownButton<T>(
              value: value,
              underline: const SizedBox(),
              isDense: true,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.deepPurple[700],
              ),
              dropdownColor: surface,
              items: items.asMap().entries.map((e) {
                final label = itemLabels != null
                    ? itemLabels[e.key]
                    : e.value.toString();
                return DropdownMenuItem<T>(
                  value: e.value,
                  child: Text(label),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ── Info row (read-only) ──────────────────────────────────────────────────

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textPrimary,
    required Color textSub,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.indigo[700], size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: textSub,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────

  Widget _sectionLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  // ── Reset button ──────────────────────────────────────────────────────────

  Widget _resetButton(Color textSub) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Reset Settings'),
          content: const Text(
              'All preferences will be restored to their defaults.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                _settings.resetAll();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings reset to defaults.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('RESET'),
            ),
          ],
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restore_rounded,
                color: Colors.redAccent.withOpacity(0.8), size: 20),
            const SizedBox(width: 10),
            Text(
              'Reset to Defaults',
              style: TextStyle(
                color: Colors.redAccent.withOpacity(0.9),
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}