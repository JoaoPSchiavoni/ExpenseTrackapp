import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendlyapp/core/api/api_exception.dart';
import 'package:spendlyapp/core/api/expense_tracker_api.dart';
import 'package:spendlyapp/core/theme/app_colors.dart';
import 'package:spendlyapp/core/theme/theme_controller.dart';
import 'package:spendlyapp/core/widgets/page_header.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({
    required this.themeController,
    required this.api,
    super.key,
  });
  final ThemeController themeController;
  final ExpenseTrackerApi api;
  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late DateTime _month;
  late Future<List<JsonMap>> _future;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _load();
  }

  String get _key => DateFormat('yyyy-MM').format(_month);
  void _load() {
    _future = Future.wait([
      widget.api.monthlyReport(_key),
      widget.api.categorySummary(_key),
      widget.api.dashboardCashFlow(months: 12),
    ]);
  }

  void _move(int offset) => setState(() {
    _month = DateTime(_month.year, _month.month + offset);
    _load();
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: 'Estatísticas',
                  subtitle: 'Relatórios reais do seu histórico financeiro.',
                  themeController: widget.themeController,
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => _move(-1),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        '${_months[_month.month - 1]} ${_month.year}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: _isCurrent ? null : () => _move(1),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                FutureBuilder<List<JsonMap>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      if (snapshot.hasError) return _Error(snapshot.error);
                      return const Padding(
                        padding: EdgeInsets.all(80),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final report = snapshot.data![0];
                    final categories = (snapshot.data![1]['items'] as List)
                        .cast<Map>();
                    final flow = (snapshot.data![2]['items'] as List)
                        .cast<Map>();
                    final income = _number(report['total_income']);
                    final expense = _number(report['total_expense']);
                    final savings = _number(report['net_savings']);
                    final rate = income == 0 ? 0 : savings / income * 100;
                    return Column(
                      children: [
                        GridView.count(
                          crossAxisCount: MediaQuery.sizeOf(context).width < 650
                              ? 2
                              : 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.35,
                          children: [
                            _Metric(
                              'Receitas',
                              _money(income, report['currency']),
                              Icons.south_west_rounded,
                              AppColors.green,
                            ),
                            _Metric(
                              'Despesas',
                              _money(expense, report['currency']),
                              Icons.north_east_rounded,
                              AppColors.pink,
                            ),
                            _Metric(
                              'Economia',
                              _money(savings, report['currency']),
                              Icons.savings_rounded,
                              AppColors.primary,
                            ),
                            _Metric(
                              'Taxa',
                              '${rate.toStringAsFixed(1)}%',
                              Icons.percent_rounded,
                              AppColors.purple,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final widgets = [
                              _Flow(flow, report['currency']),
                              _CategoryList(categories, report['currency']),
                            ];
                            return constraints.maxWidth < 760
                                ? Column(
                                    children: [
                                      widgets[0],
                                      const SizedBox(height: 18),
                                      widgets[1],
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: widgets[0]),
                                      const SizedBox(width: 18),
                                      Expanded(child: widgets[1]),
                                    ],
                                  );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _isCurrent {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }
}

const _months = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon, this.color);
  final String label, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Flow extends StatefulWidget {
  const _Flow(this.items, this.currency);

  final List<Map> items;
  final Object? currency;

  @override
  State<_Flow> createState() => _FlowState();
}

class _FlowState extends State<_Flow> {
  int? _selectedIndex;

  int get _selected {
    if (widget.items.isEmpty) return 0;
    return (_selectedIndex ?? widget.items.length - 1).clamp(
      0,
      widget.items.length - 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max = widget.items.fold<double>(
      1,
      (current, item) => [
        _number(item['income']),
        _number(item['expense']),
        current,
      ].reduce((a, b) => a > b ? a : b),
    );
    if (widget.items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Center(child: Text('Ainda não há histórico para comparar.')),
        ),
      );
    }
    final selected = widget.items[_selected];
    final selectedIncome = _number(selected['income']);
    final selectedExpense = _number(selected['expense']);
    final selectedNet = selectedIncome - selectedExpense;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Receitas x despesas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Últimos 12 meses · toque em um mês para ver os valores',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            const Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _Legend(color: AppColors.green, label: 'Receitas'),
                _Legend(color: AppColors.pink, label: 'Despesas'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              key: const ValueKey('annual-flow-selected-summary'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: .55,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _monthTitle(selected['month']),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 18,
                    runSpacing: 9,
                    children: [
                      _SelectedValue(
                        label: 'Receitas',
                        value: _money(selectedIncome, widget.currency),
                        color: AppColors.green,
                      ),
                      _SelectedValue(
                        label: 'Despesas',
                        value: _money(selectedExpense, widget.currency),
                        color: AppColors.pink,
                      ),
                      _SelectedValue(
                        label: 'Resultado',
                        value: _money(selectedNet, widget.currency),
                        color: selectedNet >= 0
                            ? AppColors.primary
                            : AppColors.danger,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) => SizedBox(
                height: 250,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 52,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var index = 4; index >= 0; index--)
                            Padding(
                              padding: EdgeInsets.only(
                                right: 7,
                                bottom: index == 0 ? 28 : 0,
                              ),
                              child: Text(
                                _compactMoney(max * index / 4, widget.currency),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: SizedBox(
                          width:
                              widget.items.length * 58.0 <
                                  constraints.maxWidth - 52
                              ? constraints.maxWidth - 52
                              : widget.items.length * 58.0,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                bottom: 30,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    for (var index = 0; index < 5; index++)
                                      Divider(
                                        height: 1,
                                        color: theme.dividerColor.withValues(
                                          alpha: .65,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (
                                    var index = 0;
                                    index < widget.items.length;
                                    index++
                                  )
                                    Expanded(
                                      child: _MonthBars(
                                        item: widget.items[index],
                                        maxValue: max,
                                        currency: widget.currency,
                                        selected: index == _selected,
                                        onTap: () => setState(
                                          () => _selectedIndex = index,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}

class _SelectedValue extends StatelessWidget {
  const _SelectedValue({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 92),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _MonthBars extends StatelessWidget {
  const _MonthBars({
    required this.item,
    required this.maxValue,
    required this.currency,
    required this.selected,
    required this.onTap,
  });
  final Map item;
  final double maxValue;
  final Object? currency;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final income = _number(item['income']);
    final expense = _number(item['expense']);
    return Semantics(
      button: true,
      label:
          '${_monthTitle(item['month'])}, receitas ${_money(income, currency)}, despesas ${_money(expense, currency)}',
      child: InkWell(
        key: ValueKey('annual-flow-month-${item['month']}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.fromLTRB(3, 5, 3, 0),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: .09)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(color: AppColors.primary.withValues(alpha: .45))
                : null,
          ),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _FlowBar(
                        value: income,
                        maxValue: maxValue,
                        maxHeight: constraints.maxHeight,
                        color: AppColors.green,
                        tooltip: 'Receitas: ${_money(income, currency)}',
                      ),
                      const SizedBox(width: 3),
                      _FlowBar(
                        value: expense,
                        maxValue: maxValue,
                        maxHeight: constraints.maxHeight,
                        color: AppColors.pink,
                        tooltip: 'Despesas: ${_money(expense, currency)}',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 29,
                child: Center(
                  child: Text(
                    _monthShort(item['month']),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.05,
                      fontSize: 9,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                      color: selected
                          ? AppColors.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowBar extends StatelessWidget {
  const _FlowBar({
    required this.value,
    required this.maxValue,
    required this.maxHeight,
    required this.color,
    required this.tooltip,
  });
  final double value;
  final double maxValue;
  final double maxHeight;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final calculatedHeight = maxHeight * value / maxValue;
    return Tooltip(
      message: tooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 10,
        height: value == 0 ? 2 : calculatedHeight.clamp(4, maxHeight),
        decoration: BoxDecoration(
          color: value == 0 ? Theme.of(context).dividerColor : color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList(this.items, this.currency);
  final List<Map> items;
  final Object? currency;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categorias no período',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 50),
              child: Center(child: Text('Sem despesas no período.')),
            )
          else
            for (final item in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.category_rounded, size: 18),
                ),
                title: Text(item['category_name'].toString()),
                trailing: Text(
                  _money(_number(item['total_spent']), currency),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
        ],
      ),
    ),
  );
}

class _Error extends StatelessWidget {
  const _Error(this.error);
  final Object? error;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(25),
      child: Text(
        error is ApiException
            ? (error! as ApiException).message
            : 'Não foi possível carregar os relatórios.',
      ),
    ),
  );
}

double _number(Object? value) => double.tryParse(value?.toString() ?? '') ?? 0;
String _money(double value, Object? currency) =>
    NumberFormat.simpleCurrency(name: currency?.toString() ?? 'BRL')
        .format(value);

const _shortMonths = [
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];

DateTime _parseMonth(Object? value) {
  final parts = value.toString().split('-');
  if (parts.length != 2) return DateTime.now();
  return DateTime(
    int.tryParse(parts[0]) ?? DateTime.now().year,
    int.tryParse(parts[1]) ?? DateTime.now().month,
  );
}

String _monthShort(Object? value) {
  final month = _parseMonth(value);
  return '${_shortMonths[month.month - 1]}\n${month.year.toString().substring(2)}';
}

String _monthTitle(Object? value) {
  final month = _parseMonth(value);
  return '${_months[month.month - 1]} de ${month.year}';
}

String _compactMoney(double value, Object? currency) {
  final code = currency?.toString() ?? 'BRL';
  final symbol = switch (code) {
    'BRL' => r'R$',
    'USD' => r'US$',
    'EUR' => '€',
    _ => code,
  };
  if (value >= 1000000) {
    return '$symbol ${(value / 1000000).toStringAsFixed(1).replaceAll('.', ',')} mi';
  }
  if (value >= 1000) {
    return '$symbol ${(value / 1000).toStringAsFixed(1).replaceAll('.', ',')} mil';
  }
  return '$symbol ${value.toStringAsFixed(0)}';
}
