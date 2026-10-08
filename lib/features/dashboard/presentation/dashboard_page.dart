import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendlyapp/core/api/api_exception.dart';
import 'package:spendlyapp/core/api/expense_tracker_api.dart';
import 'package:spendlyapp/core/theme/app_colors.dart';
import 'package:spendlyapp/core/theme/theme_controller.dart';
import 'package:spendlyapp/core/widgets/theme_toggle.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    required this.themeController,
    required this.api,
    required this.user,
    required this.onAddTransaction,
    super.key,
  });
  final ThemeController themeController;
  final ExpenseTrackerApi api;
  final JsonMap? user;
  final VoidCallback onAddTransaction;
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<_DashboardData> future;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    future = _DashboardData.load(widget.api);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: RefreshIndicator(
      onRefresh: () async {
        setState(_reload);
        await future;
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  themeController: widget.themeController,
                  user: widget.user,
                  onAdd: widget.onAddTransaction,
                ),
                const SizedBox(height: 24),
                FutureBuilder<_DashboardData>(
                  future: future,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      if (snapshot.hasError) {
                        return _Error(
                          error: snapshot.error,
                          retry: () => setState(_reload),
                        );
                      }
                      return const SizedBox(
                        height: 420,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final data = snapshot.data!;
                    return Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) =>
                              constraints.maxWidth < 820
                              ? Column(
                                  children: [
                                    _Balance(data.overview),
                                    const SizedBox(height: 18),
                                    _CashFlow(data.cashFlow),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: _Balance(data.overview),
                                    ),
                                    const SizedBox(width: 18),
                                    Expanded(
                                      flex: 7,
                                      child: _CashFlow(data.cashFlow),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Inteligência financeira',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) =>
                              constraints.maxWidth < 820
                              ? Column(
                                  children: [
                                    _BalanceProjection(data.projection),
                                    const SizedBox(height: 18),
                                    _FinancialHealth(data.health),
                                    const SizedBox(height: 18),
                                    _PeriodComparison(
                                      data.comparison,
                                      currency: data.overview['currency'],
                                    ),
                                    const SizedBox(height: 18),
                                    _Recommendations(data.recommendations),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 7,
                                          child: _BalanceProjection(
                                            data.projection,
                                          ),
                                        ),
                                        const SizedBox(width: 18),
                                        Expanded(
                                          flex: 5,
                                          child: _FinancialHealth(data.health),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _PeriodComparison(
                                            data.comparison,
                                            currency: data.overview['currency'],
                                          ),
                                        ),
                                        const SizedBox(width: 18),
                                        Expanded(
                                          child: _Recommendations(
                                            data.recommendations,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 18),
                        _Recent(data.recent),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _DashboardData {
  const _DashboardData(
    this.overview,
    this.cashFlow,
    this.recent,
    this.projection,
    this.comparison,
    this.health,
    this.recommendations,
  );
  final JsonMap overview;
  final JsonMap cashFlow;
  final List<JsonMap> recent;
  final JsonMap projection;
  final JsonMap comparison;
  final JsonMap health;
  final List<JsonMap> recommendations;
  static Future<_DashboardData> load(ExpenseTrackerApi api) async {
    try {
      await api.processDueRecurringTransactions();
    } on ApiException {
      // A schedule that cannot be processed must not hide the financial dashboard.
    }
    final result = await Future.wait<dynamic>([
      api.dashboardOverview(),
      api.dashboardCashFlow(),
      api.dashboardRecent(),
      api.balanceProjection(),
      api.periodComparison(),
      api.financialHealth(),
      api.financialRecommendations(),
    ]);
    return _DashboardData(
      result[0],
      result[1],
      result[2],
      result[3],
      result[4],
      result[5],
      result[6],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.themeController,
    required this.user,
    required this.onAdd,
  });
  final ThemeController themeController;
  final JsonMap? user;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 980;
    final name = user?['full_name']?.toString().split(' ').first ?? 'Olá';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, $name 👋',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Seu dinheiro, com mais clareza.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (isMobile)
          IconButton.filled(
            key: const ValueKey('add-transaction'),
            onPressed: onAdd,
            tooltip: 'Adicionar transação',
            icon: const Icon(Icons.add_rounded),
          )
        else
          FilledButton.icon(
            key: const ValueKey('add-transaction'),
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nova transação'),
          ),
        if (isMobile) ...[
          const SizedBox(width: 10),
          ThemeToggle(controller: themeController),
        ],
      ],
    );
  }
}

class _Balance extends StatelessWidget {
  const _Balance(this.data);
  final JsonMap data;
  @override
  Widget build(BuildContext context) => Container(
    height: 254,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF4B8AF8), Color(0xFF2867E8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: .28),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Patrimônio total',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .78),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              data['currency'].toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FittedBox(
          child: Text(
            _money(data['net_worth'], data['currency']),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.4,
            ),
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: _Hero(
                label: 'RECEITAS',
                value: _money(data['total_income'], data['currency']),
                icon: Icons.south_west_rounded,
              ),
            ),
            Expanded(
              child: _Hero(
                label: 'DESPESAS',
                value: _money(data['total_expense'], data['currency']),
                icon: Icons.north_east_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          '${data['transaction_count']} transações · ${data['active_wallets']} carteiras',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .75),
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.label, required this.value, required this.icon});
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 15, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      FittedBox(
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}

class _CashFlow extends StatefulWidget {
  const _CashFlow(this.data);
  final JsonMap data;

  @override
  State<_CashFlow> createState() => _CashFlowState();
}

class _CashFlowState extends State<_CashFlow> {
  static const _colors = [AppColors.primary, AppColors.pink];
  Timer? _rotationTimer;
  var _showDonut = false;
  var _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _scheduleRotation();
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  void _scheduleRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) setState(() => _showDonut = !_showDonut);
    });
  }

  void _selectView(bool showDonut) {
    setState(() => _showDonut = showDonut);
    _scheduleRotation();
  }

  void _selectSlice(int index) {
    setState(() => _selectedIndex = index);
    _scheduleRotation();
  }

  @override
  Widget build(BuildContext context) {
    final items = (widget.data['items'] as List).cast<Map>();
    final income = items.fold<double>(0, (total, item) {
      return total + (double.tryParse(item['income'].toString()) ?? 0);
    });
    final expense = items.fold<double>(0, (total, item) {
      return total + (double.tryParse(item['expense'].toString()) ?? 0);
    });
    final total = income + expense;
    final donutItems = <Map<String, dynamic>>[
      {
        'label': 'Entradas',
        'amount': income,
        'percentage': total == 0 ? 0.0 : income / total * 100,
      },
      {
        'label': 'Saídas',
        'amount': expense,
        'percentage': total == 0 ? 0.0 : expense / total * 100,
      },
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Fluxo de caixa',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
                _ChartSelector(showDonut: _showDonut, onChanged: _selectView),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween(begin: .97, end: 1.0).animate(animation),
                  child: child,
                ),
              ),
              child: _showDonut
                  ? _CashFlowDonut(
                      key: const ValueKey('cash-flow-donut'),
                      items: donutItems,
                      colors: _colors,
                      currency: widget.data['currency'],
                      selectedIndex: _selectedIndex,
                      onSelected: _selectSlice,
                    )
                  : _CashFlowBars(
                      key: const ValueKey('cash-flow-bars'),
                      items: items,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashFlowBars extends StatelessWidget {
  const _CashFlowBars({required this.items, super.key});
  final List<Map> items;

  @override
  Widget build(BuildContext context) {
    final max = items.fold<double>(1, (value, item) {
      final i = double.tryParse(item['income'].toString()) ?? 0;
      final e = double.tryParse(item['expense'].toString()) ?? 0;
      return [value, i, e].reduce((a, b) => a > b ? a : b);
    });
    return SizedBox(
      height: 190,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final item in items)
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _Bar(
                                value:
                                    (double.tryParse(
                                          item['income'].toString(),
                                        ) ??
                                        0) /
                                    max,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              _Bar(
                                value:
                                    (double.tryParse(
                                          item['expense'].toString(),
                                        ) ??
                                        0) /
                                    max,
                                color: AppColors.pink,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['month'].toString().substring(5),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppColors.primary, label: 'Entradas'),
              SizedBox(width: 16),
              _LegendDot(color: AppColors.pink, label: 'Saídas'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 11)),
    ],
  );
}

class _CashFlowDonut extends StatelessWidget {
  const _CashFlowDonut({
    required this.items,
    required this.colors,
    required this.currency,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });
  final List<Map<String, dynamic>> items;
  final List<Color> colors;
  final Object? currency;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final values = [for (final item in items) item['amount'] as double];
    final selected = items[selectedIndex];
    return SizedBox(
      height: 190,
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Semantics(
                label:
                    'Fluxo de caixa em gráfico de rosca. ${selected['label']}: ${(selected['percentage'] as double).toStringAsFixed(1)} por cento.',
                child: GestureDetector(
                  key: const ValueKey('interactive-cash-flow-donut'),
                  onTapDown: (details) {
                    final index = _donutIndexAt(
                      details.localPosition,
                      const Size.square(180),
                      values,
                    );
                    if (index != null) onSelected(index);
                  },
                  child: SizedBox.square(
                    dimension: 180,
                    child: CustomPaint(
                      painter: _DonutPainter(
                        values: values,
                        colors: colors,
                        selectedIndex: selectedIndex,
                        trackColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selected['label'].toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${(selected['percentage'] as double).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              _money(selected['amount'], currency),
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < items.length; index++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ChoiceChip(
                    label: Text(items[index]['label'].toString()),
                    avatar: CircleAvatar(
                      radius: 5,
                      backgroundColor: colors[index],
                    ),
                    selected: selectedIndex == index,
                    onSelected: (_) => onSelected(index),
                    showCheckmark: false,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.color});
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => Container(
      width: 10,
      height: c.maxHeight * value,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}

class _ChartSelector extends StatelessWidget {
  const _ChartSelector({required this.showDonut, required this.onChanged});
  final bool showDonut;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ChartButton(
          key: const ValueKey('cash-flow-bars-button'),
          tooltip: 'Exibir barras',
          icon: Icons.bar_chart_rounded,
          selected: !showDonut,
          onPressed: () => onChanged(false),
        ),
        _ChartButton(
          key: const ValueKey('cash-flow-donut-button'),
          tooltip: 'Exibir gráfico de rosca',
          icon: Icons.donut_large_rounded,
          selected: showDonut,
          onPressed: () => onChanged(true),
        ),
      ],
    ),
  );
}

class _ChartButton extends StatelessWidget {
  const _ChartButton({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onPressed,
    super.key,
  });
  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 34,
        height: 32,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected
              ? Colors.white
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}

int? _donutIndexAt(Offset position, Size size, List<double> values) {
  final center = size.center(Offset.zero);
  final vector = position - center;
  final distance = vector.distance;
  if (distance < 55 || distance > size.width / 2) return null;
  final total = values.fold<double>(0, (sum, value) => sum + value);
  if (total <= 0) return null;
  var angle = math.atan2(vector.dy, vector.dx) + math.pi / 2;
  if (angle < 0) angle += math.pi * 2;
  var cursor = 0.0;
  for (var index = 0; index < values.length; index++) {
    cursor += values[index] / total * math.pi * 2;
    if (angle <= cursor) return index;
  }
  return values.length - 1;
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.values,
    required this.colors,
    required this.selectedIndex,
    required this.trackColor,
  });
  final List<double> values;
  final List<Color> colors;
  final int selectedIndex;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 18;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;
    const gap = .035;
    final total = values.fold<double>(0, (sum, value) => sum + value);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30,
    );
    if (total <= 0) return;
    var angle = start;
    for (var index = 0; index < values.length; index++) {
      final sweep = values[index] / total * math.pi * 2;
      final paint = Paint()
        ..color = colors[index % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = index == selectedIndex ? 38 : 30
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        bounds,
        angle + gap / 2,
        math.max(0, sweep - gap),
        false,
        paint,
      );
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.values != values ||
      oldDelegate.trackColor != trackColor;
}

class _BalanceProjection extends StatelessWidget {
  const _BalanceProjection(this.data);
  final JsonMap data;

  @override
  Widget build(BuildContext context) {
    final items = (data['items'] as List? ?? const []).cast<Map>();
    final values = [
      for (final item in items)
        double.tryParse(item['projected_balance'].toString()) ?? 0,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.show_chart_rounded, color: AppColors.primary),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Projeção de saldo',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Estimativa baseada nas suas recorrências ativas.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            if (items.isEmpty)
              const SizedBox(
                height: 150,
                child: Center(child: Text('Sem dados para projetar.')),
              )
            else ...[
              SizedBox(
                height: 120,
                width: double.infinity,
                child: CustomPaint(
                  key: const ValueKey('balance-projection-chart'),
                  painter: _ProjectionPainter(
                    values: values,
                    lineColor: AppColors.purple,
                    fillColor: AppColors.purple.withValues(alpha: .14),
                    gridColor: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final item in items)
                    Expanded(
                      child: Text(
                        item['month'].toString().substring(5),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Saldo ao final: ${_money(items.last['projected_balance'], data['currency'])}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProjectionPainter extends CustomPainter {
  const _ProjectionPainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
  });
  final List<double> values;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = math.max(1.0, maxValue - minValue);
    final points = <Offset>[
      for (var index = 0; index < values.length; index++)
        Offset(
          values.length == 1
              ? size.width / 2
              : index * size.width / (values.length - 1),
          size.height -
              ((values[index] - minValue) / range * (size.height - 16)) -
              8,
        ),
    ];
    for (var row = 0; row < 3; row++) {
      final y = row * size.height / 2;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = gridColor
          ..strokeWidth = 1,
      );
    }
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    final area = Path.from(line)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = fillColor);
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _ProjectionPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.gridColor != gridColor;
}

class _FinancialHealth extends StatelessWidget {
  const _FinancialHealth(this.data);
  final JsonMap data;

  @override
  Widget build(BuildContext context) {
    final score = (int.tryParse(data['score'].toString()) ?? 0).clamp(0, 100);
    final savingsRate = double.tryParse(data['savings_rate'].toString()) ?? 0;
    final reserveMonths =
        double.tryParse(data['reserve_months'].toString()) ?? 0;
    final budgetsAtRisk = int.tryParse(data['budgets_at_risk'].toString()) ?? 0;
    final color = score >= 80
        ? AppColors.green
        : score >= 60
        ? AppColors.primary
        : score >= 40
        ? AppColors.amber
        : AppColors.danger;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saúde financeira',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            Center(
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: score / 100),
                builder: (context, progress, _) => SizedBox.square(
                  dimension: 156,
                  child: CustomPaint(
                    key: const ValueKey('financial-health-score'),
                    painter: _HealthGaugePainter(
                      progress: progress,
                      color: color,
                      trackColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      markerColor: Theme.of(context).colorScheme.outline
                          .withValues(alpha: .45),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$score',
                            style: const TextStyle(
                              fontSize: 38,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_healthStatus(data['status'])} · 100',
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                data['summary']?.toString() ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  label: savingsRate < 0
                      ? 'Mês em déficit'
                      : 'Economia ${savingsRate.toStringAsFixed(1)}%',
                  color: savingsRate < 0 ? AppColors.danger : AppColors.green,
                ),
                _MetricChip(
                  label: reserveMonths <= 0
                      ? 'Sem reserva'
                      : 'Reserva ${reserveMonths.toStringAsFixed(1)} meses',
                  color: AppColors.purple,
                ),
                _MetricChip(
                  label: budgetsAtRisk == 1
                      ? '1 orçamento em risco'
                      : '$budgetsAtRisk orçamentos em risco',
                  color: AppColors.amber,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _healthStatus(Object? status) => switch (status?.toString()) {
  'HEALTHY' => 'Saudável',
  'STABLE' => 'Estável',
  'ATTENTION' => 'Atenção',
  _ => 'Crítica',
};

class _HealthGaugePainter extends CustomPainter {
  const _HealthGaugePainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.markerColor,
  });
  final double progress;
  final Color color;
  final Color trackColor;
  final Color markerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 15;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;
    canvas.drawArc(
      bounds,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
    );
    if (progress > 0) {
      canvas.drawArc(
        bounds,
        startAngle,
        math.pi * 2 * progress.clamp(0, 1),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.butt,
      );
    }
    final markerPaint = Paint()
      ..color = markerColor
      ..strokeWidth = 2;
    for (var index = 0; index < 4; index++) {
      final angle = startAngle + index * math.pi / 2;
      final outer =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius + 7);
      final inner =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius - 7);
      canvas.drawLine(inner, outer, markerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HealthGaugePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.markerColor != markerColor;
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _PeriodComparison extends StatelessWidget {
  const _PeriodComparison(this.data, {required this.currency});
  final JsonMap data;
  final Object? currency;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comparação entre períodos',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${data['previous_period']}  →  ${data['current_period']}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _ComparisonRow(
            label: 'Receitas',
            previous: data['previous_income'],
            current: data['current_income'],
            change: data['income_change_percentage'],
            currency: currency,
            positiveIsGood: true,
          ),
          const Divider(height: 24),
          _ComparisonRow(
            label: 'Despesas',
            previous: data['previous_expense'],
            current: data['current_expense'],
            change: data['expense_change_percentage'],
            currency: currency,
            positiveIsGood: false,
          ),
        ],
      ),
    ),
  );
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.previous,
    required this.current,
    required this.change,
    required this.currency,
    required this.positiveIsGood,
  });
  final String label;
  final Object? previous;
  final Object? current;
  final Object? change;
  final Object? currency;
  final bool positiveIsGood;

  @override
  Widget build(BuildContext context) {
    final delta = double.tryParse(change?.toString() ?? '');
    final good = delta == null || delta == 0 || (delta > 0) == positiveIsGood;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                '${_money(previous, currency)} → ${_money(current, currency)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: (good ? AppColors.green : AppColors.pink).withValues(
              alpha: .12,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            delta == null
                ? 'Novo'
                : '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}%',
            style: TextStyle(
              color: good ? AppColors.green : AppColors.pink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _Recommendations extends StatelessWidget {
  const _Recommendations(this.items);
  final List<JsonMap> items;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.amber),
              SizedBox(width: 9),
              Text(
                'Recomendações',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: CircleAvatar(
                radius: 17,
                backgroundColor: _priorityColor(item['priority'])
                    .withValues(alpha: .13),
                child: Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 18,
                  color: _priorityColor(item['priority']),
                ),
              ),
              title: Text(
                item['title'].toString(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(item['message'].toString()),
            ),
        ],
      ),
    ),
  );
}

Color _priorityColor(Object? priority) => switch (priority?.toString()) {
  'HIGH' => AppColors.pink,
  'MEDIUM' => AppColors.amber,
  _ => AppColors.primary,
};

class _Recent extends StatelessWidget {
  const _Recent(this.items);
  final List<JsonMap> items;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transações recentes',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: Text('Nenhuma transação ainda.')),
            )
          else
            for (final item in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor:
                      (item['transaction_type'] == 'INCOME'
                              ? AppColors.green
                              : AppColors.pink)
                          .withValues(alpha: .14),
                  child: Icon(
                    item['transaction_type'] == 'INCOME'
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    color: item['transaction_type'] == 'INCOME'
                        ? AppColors.green
                        : AppColors.pink,
                  ),
                ),
                title: Text(
                  item['description']?.toString() ??
                      item['category_name']?.toString() ??
                      'Transação',
                ),
                subtitle: Text(
                  '${item['wallet_name']} · ${DateFormat('dd/MM').format(DateTime.parse(item['occurred_at'].toString()).toLocal())}',
                ),
                trailing: Text(
                  '${item['transaction_type'] == 'INCOME' ? '+' : '-'} ${_money(item['amount'], item['currency'])}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: item['transaction_type'] == 'INCOME'
                        ? AppColors.green
                        : null,
                  ),
                ),
              ),
        ],
      ),
    ),
  );
}

class _Error extends StatelessWidget {
  const _Error({required this.error, required this.retry});
  final Object? error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.pink),
          const SizedBox(height: 12),
          Text(
            error is ApiException
                ? (error! as ApiException).message
                : 'Falha ao carregar o painel.',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    ),
  );
}

String _money(Object? value, Object? currency) {
  final number = double.tryParse(value?.toString() ?? '') ?? 0;
  return NumberFormat.simpleCurrency(name: currency?.toString() ?? 'BRL')
      .format(number);
}
