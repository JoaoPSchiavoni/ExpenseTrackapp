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
                              _Flow(flow),
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

class _Flow extends StatelessWidget {
  const _Flow(this.items);
  final List<Map> items;
  @override
  Widget build(BuildContext context) {
    final max = items.fold<double>(
      1,
      (current, item) => [
        _number(item['income']),
        _number(item['expense']),
        current,
      ].reduce((a, b) => a > b ? a : b),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evolução anual',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 260,
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
                                Container(
                                  width: 7,
                                  height: 210 * _number(item['income']) / max,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 2),
                                Container(
                                  width: 7,
                                  height: 210 * _number(item['expense']) / max,
                                  color: AppColors.pink,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            item['month'].toString().substring(5),
                            style: const TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
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
