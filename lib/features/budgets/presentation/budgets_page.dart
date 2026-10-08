import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendlyapp/core/api/api_exception.dart';
import 'package:spendlyapp/core/api/expense_tracker_api.dart';
import 'package:spendlyapp/core/theme/app_colors.dart';
import 'package:spendlyapp/core/theme/theme_controller.dart';
import 'package:spendlyapp/core/widgets/page_header.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({
    required this.themeController,
    required this.api,
    super.key,
  });
  final ThemeController themeController;
  final ExpenseTrackerApi api;
  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  late Future<List<List<JsonMap>>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = Future.wait([
      widget.api.budgets(),
      widget.api.budgetStatuses(),
      widget.api.categories(),
    ]);
  }

  void _refresh() => setState(_load);

  Future<void> _run(Future<void> Function() action, String message) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      _refresh();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _edit(List<JsonMap> categories, {JsonMap? budget}) async {
    var categoryId = budget?['category_id'] as int?;
    final limit = TextEditingController(
      text: budget?['limit_amount']?.toString(),
    );
    var period = budget?['period']?.toString() ?? 'MONTHLY';
    final threshold = TextEditingController(
      text: budget?['alert_threshold']?.toString() ?? '80',
    );
    var enabled = budget?['alerts_enabled'] as bool? ?? true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(budget == null ? 'Novo orçamento' : 'Editar orçamento'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (budget == null)
                  DropdownButtonFormField<int?>(
                    initialValue: categoryId,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Todas as categorias'),
                      ),
                      ...categories.map(
                        (item) => DropdownMenuItem<int?>(
                          value: item['id'] as int,
                          child: Text(item['name'].toString()),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => categoryId = value),
                    decoration: const InputDecoration(
                      labelText: 'Categoria (opcional)',
                      helperText: 'Sem categoria, o limite considera todas as despesas.',
                    ),
                  ),
                if (budget == null) const SizedBox(height: 12),
                TextField(
                  controller: limit,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Limite'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: period,
                  items: const [
                    DropdownMenuItem(value: 'WEEKLY', child: Text('Semanal')),
                    DropdownMenuItem(value: 'MONTHLY', child: Text('Mensal')),
                  ],
                  onChanged: (value) => setDialogState(() => period = value!),
                  decoration: const InputDecoration(labelText: 'Período'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: threshold,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Alertar em (%)',
                  ),
                ),
                SwitchListTile(
                  value: enabled,
                  onChanged: (value) => setDialogState(() => enabled = value),
                  title: const Text('Alertas ativos'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    final body = <String, dynamic>{
      'limit_amount': limit.text.replaceAll(',', '.'),
      'period': period,
      'alert_threshold': int.tryParse(threshold.text) ?? 80,
      'alerts_enabled': enabled,
    };
    if (budget == null && categoryId != null) {
      body['category_id'] = categoryId;
    }
    await _run(() async {
      budget == null
          ? await widget.api.createBudget(body)
          : await widget.api.updateBudget(budget['id'] as int, body);
    }, 'Orçamento salvo.');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: 'Orçamentos',
                  subtitle: 'Limites e alertas calculados em tempo real.',
                  themeController: widget.themeController,
                ),
                const SizedBox(height: 22),
                FutureBuilder<List<List<JsonMap>>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      if (snapshot.hasError) {
                        return _Error(snapshot.error, _refresh);
                      }
                      return const Padding(
                        padding: EdgeInsets.all(80),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final budgets = snapshot.data![0];
                    final statuses = snapshot.data![1];
                    final categories = snapshot.data![2];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: () => _edit(categories),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Novo orçamento'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (budgets.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 46,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Nenhum orçamento criado.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          for (final budget in budgets)
                            _budgetCard(budget, statuses, categories),
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

  Widget _budgetCard(
    JsonMap budget,
    List<JsonMap> statuses,
    List<JsonMap> categories,
  ) {
    final status = _find(statuses, 'budget_id', budget['id']);
    final categoryId = budget['category_id'];
    final category = categoryId == null
        ? null
        : _find(categories, 'id', categoryId);
    final progress = ((_number(status?['usage_percentage']) / 100).clamp(
      0.0,
      1.0,
    ));
    final exceeded = status?['status'] == 'EXCEEDED';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      (exceeded ? AppColors.danger : AppColors.primary)
                          .withValues(alpha: .14),
                  child: Icon(
                    exceeded
                        ? Icons.warning_rounded
                        : categoryId == null
                        ? Icons.donut_large_rounded
                        : Icons.category_rounded,
                    color: exceeded ? AppColors.danger : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryId == null
                            ? 'Orçamento geral'
                            : category?['name']?.toString() ?? 'Categoria',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        budget['period'] == 'MONTHLY' ? 'Mensal' : 'Semanal',
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: exceeded ? AppColors.danger : AppColors.primary,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    final id = budget['id'] as int;
                    if (value == 'detail') _detail(id);
                    if (value == 'edit') _edit(categories, budget: budget);
                    if (value == 'delete') {
                      _run(
                        () => widget.api.deleteBudget(id),
                        'Orçamento excluído.',
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'detail', child: Text('Ver status')),
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Excluir')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              borderRadius: BorderRadius.circular(10),
              color: exceeded ? AppColors.danger : AppColors.primary,
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Text(
                  'Gasto: ${_money(status?['spent_amount'], status?['currency'])}',
                ),
                const Spacer(),
                Text(
                  'Limite: ${_money(status?['limit_amount'] ?? budget['limit_amount'], status?['currency'] ?? 'BRL')}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _detail(int id) async {
    try {
      final budget = await widget.api.budget(id);
      final status = await widget.api.budgetStatus(id);
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Status do orçamento'),
          content: SelectableText(
            'Período: ${status['period_start']} a ${status['period_end']}\nGasto: ${_money(status['spent_amount'], status['currency'])}\nRestante: ${_money(status['remaining_amount'], status['currency'])}\nUso: ${status['usage_percentage']}%\nStatus: ${status['status']}\nAlertas: ${budget['alerts_enabled'] == true ? 'ativos' : 'desativados'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

JsonMap? _find(List<JsonMap> items, String key, Object? value) {
  for (final item in items) {
    if (item[key] == value) return item;
  }
  return null;
}

double _number(Object? value) => double.tryParse(value?.toString() ?? '') ?? 0;
String _money(Object? value, Object? currency) =>
    NumberFormat.simpleCurrency(name: currency?.toString() ?? 'BRL')
        .format(_number(value));

class _Error extends StatelessWidget {
  const _Error(this.error, this.retry);
  final Object? error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          Text(
            error is ApiException
                ? (error! as ApiException).message
                : 'Falha ao carregar orçamentos.',
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: retry, child: const Text('Tentar novamente')),
        ],
      ),
    ),
  );
}
