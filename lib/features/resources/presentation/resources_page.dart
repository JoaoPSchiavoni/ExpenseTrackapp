import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendlyapp/core/api/api_exception.dart';
import 'package:spendlyapp/core/api/expense_tracker_api.dart';
import 'package:spendlyapp/core/theme/app_colors.dart';
import 'package:spendlyapp/core/theme/theme_controller.dart';
import 'package:spendlyapp/core/widgets/page_header.dart';

class ResourcesPage extends StatefulWidget {
  const ResourcesPage({
    required this.api,
    required this.themeController,
    super.key,
  });

  final ExpenseTrackerApi api;
  final ThemeController themeController;

  @override
  State<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends State<ResourcesPage> {
  late Future<_ResourceData> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _ResourceData.load(widget.api);
  }

  void _refresh() => setState(_reload);

  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success)));
      _refresh();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: 'Central financeira',
                  subtitle: 'Carteiras, recorrências, metas, importações, câmbio e alertas.',
                  themeController: widget.themeController,
                ),
                const SizedBox(height: 22),
                FutureBuilder<_ResourceData>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(70),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return _ErrorCard(
                        error: snapshot.error,
                        onRetry: _refresh,
                      );
                    }
                    final data = snapshot.requireData;
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 900 ? 2 : 1;
                        final width = columns == 2
                            ? (constraints.maxWidth - 18) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 18,
                          runSpacing: 18,
                          children: [
                            SizedBox(
                              width: width,
                              child: _WalletsCard(
                                data: data,
                                api: widget.api,
                                run: _run,
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: _CategoriesCard(
                                data: data,
                                api: widget.api,
                                run: _run,
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: _GoalsCard(
                                data: data,
                                api: widget.api,
                                run: _run,
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: _RecurringCard(
                                data: data,
                                api: widget.api,
                                run: _run,
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: _ImportsCard(
                                data: data,
                                api: widget.api,
                                run: _run,
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: _CurrencyCard(data: data, api: widget.api),
                            ),
                            SizedBox(
                              width: width,
                              child: _AlertsCard(
                                data: data,
                                api: widget.api,
                                run: _run,
                              ),
                            ),
                            SizedBox(
                              width: constraints.maxWidth,
                              child: _AutomationCard(
                                data: data,
                                api: widget.api,
                                run: _run,
                              ),
                            ),
                            SizedBox(
                              width: constraints.maxWidth,
                              child: _PortfolioToolsCard(api: widget.api),
                            ),
                            SizedBox(
                              width: constraints.maxWidth,
                              child: _TransactionsCard(
                                data: data,
                                api: widget.api,
                                run: _run,
                              ),
                            ),
                          ],
                        );
                      },
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
}

class _ResourceData {
  const _ResourceData({
    required this.wallets,
    required this.categories,
    required this.goals,
    required this.recurring,
    required this.imports,
    required this.currencies,
    required this.currencyCatalogOnline,
    required this.alerts,
    required this.rules,
    required this.subscriptions,
    required this.billingAlerts,
  });
  final List<JsonMap> wallets;
  final List<JsonMap> categories;
  final List<JsonMap> goals;
  final List<JsonMap> recurring;
  final List<JsonMap> imports;
  final List<JsonMap> currencies;
  final bool currencyCatalogOnline;
  final List<JsonMap> alerts;
  final List<JsonMap> rules;
  final List<JsonMap> subscriptions;
  final List<JsonMap> billingAlerts;

  static const _fallbackCurrencies = <JsonMap>[
    {'code': 'BRL', 'name': 'Brazilian Real', 'symbol': r'R$'},
    {'code': 'USD', 'name': 'United States Dollar', 'symbol': r'$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
    {'code': 'ARS', 'name': 'Argentine Peso', 'symbol': r'$'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': r'$'},
    {'code': 'CHF', 'name': 'Swiss Franc', 'symbol': 'CHF'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
    {'code': 'MXN', 'name': 'Mexican Peso', 'symbol': r'$'},
  ];

  static Future<_CurrencyCatalog> _loadCurrencies(ExpenseTrackerApi api) async {
    try {
      final currencies = await api.currencies();
      if (currencies.isNotEmpty) {
        return _CurrencyCatalog(currencies, true);
      }
    } on ApiException {
      // A temporary catalog failure must not make every resource unavailable.
    }
    return const _CurrencyCatalog(_fallbackCurrencies, false);
  }

  static Future<List<JsonMap>> _loadOptional(
    Future<List<JsonMap>> Function() loader,
  ) async {
    try {
      return await loader();
    } on ApiException {
      return const [];
    }
  }

  static Future<_ResourceData> load(ExpenseTrackerApi api) async {
    final values = await Future.wait<dynamic>([
      api.wallets(),
      api.categories(),
      api.goals(),
      api.recurringTransactions(),
      api.imports(),
      _loadCurrencies(api),
      api.alerts(activeOnly: false),
      _loadOptional(api.categorizationRules),
      _loadOptional(api.subscriptions),
      _loadOptional(api.billingAlerts),
    ]);
    final currencyCatalog = values[5] as _CurrencyCatalog;
    return _ResourceData(
      wallets: values[0],
      categories: values[1],
      goals: values[2],
      recurring: values[3],
      imports: values[4],
      currencies: currencyCatalog.currencies,
      currencyCatalogOnline: currencyCatalog.online,
      alerts: values[6],
      rules: values[7],
      subscriptions: values[8],
      billingAlerts: values[9],
    );
  }
}

class _CurrencyCatalog {
  const _CurrencyCatalog(this.currencies, this.online);

  final List<JsonMap> currencies;
  final bool online;
}

typedef _RunAction = Future<void> Function(Future<void> Function(), String);

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.child,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    ),
  );
}

class _WalletsCard extends StatelessWidget {
  const _WalletsCard({
    required this.data,
    required this.api,
    required this.run,
  });
  final _ResourceData data;
  final ExpenseTrackerApi api;
  final _RunAction run;
  @override
  Widget build(BuildContext context) => _SectionCard(
    icon: Icons.account_balance_wallet_rounded,
    title: 'Carteiras',
    subtitle: '${data.wallets.length} contas ativas',
    action: IconButton.filledTonal(
      onPressed: () => _walletDialog(context),
      icon: const Icon(Icons.add_rounded),
    ),
    child: _items(
      context,
      data.wallets,
      'Crie sua primeira carteira.',
      (item) =>
          '${item['name']} · ${item['currency']}  •  ${_money(item['balance'], item['currency'])}',
      (item) => PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'detail') {
            _showJson(
              context,
              'Detalhes da carteira',
              api.wallet(item['id'] as int),
            );
          }
          if (value == 'edit') _walletDialog(context, item: item);
          if (value == 'delete') {
            run(
              () => api.deleteWallet(item['id'] as int),
              'Carteira arquivada.',
            );
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'detail', child: Text('Ver detalhes')),
          PopupMenuItem(value: 'edit', child: Text('Editar')),
          PopupMenuItem(value: 'delete', child: Text('Arquivar')),
        ],
      ),
    ),
  );

  Future<void> _walletDialog(BuildContext context, {JsonMap? item}) async {
    final name = TextEditingController(text: item?['name']?.toString());
    final balance = TextEditingController(text: '0.00');
    var currency = item?['currency']?.toString() ?? 'BRL';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(item == null ? 'Nova carteira' : 'Editar carteira'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField(
                initialValue: currency,
                items: ['BRL', 'USD', 'EUR', 'GBP']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => currency = value!),
                decoration: const InputDecoration(labelText: 'Moeda'),
              ),
              if (item == null) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: balance,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Saldo inicial'),
                ),
              ],
            ],
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
    if (ok == true) {
      await run(() async {
        if (item == null) {
          await api.createWallet({
            'name': name.text.trim(),
            'currency': currency,
            'initial_balance': balance.text.replaceAll(',', '.'),
          });
        } else {
          await api.updateWallet(item['id'] as int, {
            'name': name.text.trim(),
            'currency': currency,
          });
        }
      }, 'Carteira salva.');
    }
  }
}

class _CategoriesCard extends StatelessWidget {
  const _CategoriesCard({
    required this.data,
    required this.api,
    required this.run,
  });
  final _ResourceData data;
  final ExpenseTrackerApi api;
  final _RunAction run;
  @override
  Widget build(BuildContext context) => _SectionCard(
    icon: Icons.category_rounded,
    title: 'Categorias',
    subtitle: 'Organize suas despesas',
    action: IconButton.filledTonal(
      onPressed: () => _dialog(context),
      icon: const Icon(Icons.add_rounded),
    ),
    child: _items(
      context,
      data.categories,
      'Nenhuma categoria cadastrada.',
      (item) =>
          '${item['name']}${item['description'] == null ? '' : ' · ${item['description']}'}',
      (item) => PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'detail') {
            _showJson(
              context,
              'Detalhes da categoria',
              api.category(item['id'] as int),
            );
          }
          if (value == 'edit') _dialog(context, item: item);
          if (value == 'delete') {
            run(
              () => api.deleteCategory(item['id'] as int),
              'Categoria excluída.',
            );
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'detail', child: Text('Ver detalhes')),
          PopupMenuItem(value: 'edit', child: Text('Editar')),
          PopupMenuItem(value: 'delete', child: Text('Excluir')),
        ],
      ),
    ),
  );
  Future<void> _dialog(BuildContext context, {JsonMap? item}) async {
    final name = TextEditingController(text: item?['name']?.toString());
    final description = TextEditingController(
      text: item?['description']?.toString(),
    );
    final ok = await _formDialog(
      context,
      item == null ? 'Nova categoria' : 'Editar categoria',
      [
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: description,
          decoration: const InputDecoration(labelText: 'Descrição'),
        ),
      ],
    );
    if (ok) {
      await run(() async {
        final body = {
          'name': name.text.trim(),
          'description': description.text.trim(),
        };
        item == null
            ? await api.createCategory(body)
            : await api.updateCategory(item['id'] as int, body);
      }, 'Categoria salva.');
    }
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({required this.data, required this.api, required this.run});
  final _ResourceData data;
  final ExpenseTrackerApi api;
  final _RunAction run;
  @override
  Widget build(BuildContext context) => _SectionCard(
    icon: Icons.flag_rounded,
    title: 'Metas',
    subtitle: 'Transforme planos em progresso',
    action: IconButton.filledTonal(
      onPressed: () => _goalDialog(context),
      icon: const Icon(Icons.add_rounded),
    ),
    child: _items(
      context,
      data.goals,
      'Nenhuma meta cadastrada.',
      (item) =>
          '${item['name']} · ${_money(item['current_amount'], item['currency'])} de ${_money(item['target_amount'], item['currency'])}',
      (item) => PopupMenuButton<String>(
        onSelected: (value) {
          final id = item['id'] as int;
          if (value == 'detail') {
            _showJson(context, 'Detalhes da meta', api.goal(id));
          }
          if (value == 'edit') _goalDialog(context, item: item);
          if (value == 'contribute') _contributions(context, id);
          if (value == 'delete') {
            run(() => api.deleteGoal(id), 'Meta excluída.');
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'detail', child: Text('Ver detalhes')),
          PopupMenuItem(value: 'contribute', child: Text('Contribuições')),
          PopupMenuItem(value: 'edit', child: Text('Editar')),
          PopupMenuItem(value: 'delete', child: Text('Excluir')),
        ],
      ),
    ),
  );
  Future<void> _goalDialog(BuildContext context, {JsonMap? item}) async {
    final name = TextEditingController(text: item?['name']?.toString());
    final amount = TextEditingController(
      text: item?['target_amount']?.toString(),
    );
    final description = TextEditingController(
      text: item?['description']?.toString(),
    );
    final ok = await _formDialog(
      context,
      item == null ? 'Nova meta' : 'Editar meta',
      [
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: amount,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Valor alvo'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: description,
          decoration: const InputDecoration(labelText: 'Descrição'),
        ),
      ],
    );
    if (ok) {
      await run(() async {
        final body = {
          'name': name.text.trim(),
          'target_amount': amount.text.replaceAll(',', '.'),
          'description': description.text.trim(),
        };
        item == null
            ? await api.createGoal(body)
            : await api.updateGoal(item['id'] as int, body);
      }, 'Meta salva.');
    }
  }

  Future<void> _contributions(BuildContext context, int id) async {
    final contributions = await api.contributions(id);
    if (!context.mounted) return;
    final amount = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contribuições'),
        content: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in contributions)
                ListTile(
                  title: Text(_money(item['amount'], 'BRL')),
                  subtitle: Text(item['note']?.toString() ?? 'Sem nota'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await run(() async {
                        await api.deleteContribution(id, item['id'] as int);
                      }, 'Contribuição removida.');
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ),
              const Divider(),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nova contribuição',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          FilledButton(
            onPressed: () async {
              await run(() async {
                await api.addContribution(id, {
                  'amount': amount.text.replaceAll(',', '.'),
                });
              }, 'Contribuição adicionada.');
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }
}

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
    required this.data,
    required this.api,
    required this.run,
  });
  final _ResourceData data;
  final ExpenseTrackerApi api;
  final _RunAction run;

  static const _frequencyLabels = <String, String>{
    'DAILY': 'Diária',
    'WEEKLY': 'Semanal',
    'MONTHLY': 'Mensal',
    'YEARLY': 'Anual',
  };

  @override
  Widget build(BuildContext context) => _SectionCard(
    icon: Icons.event_repeat_rounded,
    title: 'Transações recorrentes',
    subtitle: 'Lançamentos automáticos no vencimento',
    action: IconButton.filledTonal(
      key: const ValueKey('add-recurring-transaction'),
      onPressed: data.wallets.isEmpty ? null : () => _recurringDialog(context),
      tooltip: data.wallets.isEmpty
          ? 'Crie uma carteira primeiro'
          : 'Nova recorrência',
      icon: const Icon(Icons.add_rounded),
    ),
    child: _items(
      context,
      data.recurring,
      data.wallets.isEmpty
          ? 'Crie uma carteira para automatizar movimentações.'
          : 'Nenhuma recorrência cadastrada.',
      (item) {
        final matchingWallets = data.wallets.where(
          (candidate) => candidate['id'] == item['wallet_id'],
        );
        final wallet = matchingWallets.isEmpty ? null : matchingWallets.first;
        final frequency =
            _frequencyLabels[item['frequency']] ?? item['frequency'].toString();
        final state = item['is_active'] == true ? 'ativa' : 'pausada';
        return '${item['description'] ?? item['transaction_type']} · $frequency · $state\n${wallet?['name'] ?? 'Carteira'} · ${_money(item['amount'], wallet?['currency'] ?? 'BRL')}';
      },
      (item) => PopupMenuButton<String>(
        onSelected: (value) {
          final id = item['id'] as int;
          if (value == 'detail') {
            _showJson(
              context,
              'Detalhes da recorrência',
              api.recurringTransaction(id),
            );
          }
          if (value == 'edit') _recurringDialog(context, item: item);
          if (value == 'toggle') {
            final activate = item['is_active'] != true;
            run(
              () async =>
                  api.updateRecurringTransaction(id, {'is_active': activate}),
              activate ? 'Recorrência ativada.' : 'Recorrência pausada.',
            );
          }
          if (value == 'delete') {
            run(
              () => api.deleteRecurringTransaction(id),
              'Recorrência excluída.',
            );
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'detail', child: Text('Ver detalhes')),
          const PopupMenuItem(value: 'edit', child: Text('Editar')),
          PopupMenuItem(
            value: 'toggle',
            child: Text(item['is_active'] == true ? 'Pausar' : 'Ativar'),
          ),
          const PopupMenuItem(value: 'delete', child: Text('Excluir')),
        ],
      ),
    ),
  );

  Future<void> _recurringDialog(BuildContext context, {JsonMap? item}) async {
    final amount = TextEditingController(text: item?['amount']?.toString());
    final description = TextEditingController(
      text: item?['description']?.toString(),
    );
    final interval = TextEditingController(
      text: item?['interval_count']?.toString() ?? '1',
    );
    var walletId =
        item?['wallet_id'] as int? ?? data.wallets.first['id'] as int;
    var categoryId = item?['category_id'] as int?;
    var transactionType = item?['transaction_type']?.toString() ?? 'EXPENSE';
    var frequency = item?['frequency']?.toString() ?? 'MONTHLY';
    var startDate = item == null
        ? DateUtils.dateOnly(DateTime.now())
        : DateTime.parse(item['start_date'].toString());

    final ok =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: Text(
                item == null ? 'Nova recorrência' : 'Editar recorrência',
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: walletId,
                        isExpanded: true,
                        items: data.wallets
                            .map(
                              (wallet) => DropdownMenuItem(
                                value: wallet['id'] as int,
                                child: Text(wallet['name'].toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => walletId = value!),
                        decoration: const InputDecoration(
                          labelText: 'Carteira',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        initialValue: categoryId,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Sem categoria'),
                          ),
                          ...data.categories.map(
                            (category) => DropdownMenuItem<int?>(
                              value: category['id'] as int,
                              child: Text(category['name'].toString()),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => categoryId = value),
                        decoration: const InputDecoration(
                          labelText: 'Categoria (opcional)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'EXPENSE',
                            label: Text('Despesa'),
                            icon: Icon(Icons.north_east_rounded),
                          ),
                          ButtonSegment(
                            value: 'INCOME',
                            label: Text('Receita'),
                            icon: Icon(Icons.south_west_rounded),
                          ),
                        ],
                        selected: {transactionType},
                        onSelectionChanged: (selection) =>
                            setState(() => transactionType = selection.first),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const ValueKey('recurring-amount'),
                        controller: amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Valor'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: description,
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: frequency,
                              isExpanded: true,
                              items: _frequencyLabels.entries
                                  .map(
                                    (entry) => DropdownMenuItem(
                                      value: entry.key,
                                      child: Text(entry.value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => frequency = value!),
                              decoration: const InputDecoration(
                                labelText: 'Frequência',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: interval,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'A cada',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Primeiro lançamento'),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy').format(startDate),
                        ),
                        trailing: const Icon(Icons.calendar_month_rounded),
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (selected != null) {
                            setState(() => startDate = selected);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  key: const ValueKey('save-recurring-transaction'),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Salvar'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (ok) {
      await run(() async {
        final body = <String, dynamic>{
          'wallet_id': walletId,
          'amount': amount.text.replaceAll(',', '.'),
          'transaction_type': transactionType,
          'description': description.text.trim(),
          'frequency': frequency,
          'interval_count': int.tryParse(interval.text) ?? 1,
          'start_date': DateFormat('yyyy-MM-dd').format(startDate),
        };
        if (categoryId != null) body['category_id'] = categoryId;
        item == null
            ? await api.createRecurringTransaction(body)
            : await api.updateRecurringTransaction(item['id'] as int, body);
      }, 'Recorrência salva.');
    }
  }
}

class _ImportsCard extends StatelessWidget {
  const _ImportsCard({
    required this.data,
    required this.api,
    required this.run,
  });
  final _ResourceData data;
  final ExpenseTrackerApi api;
  final _RunAction run;
  @override
  Widget build(BuildContext context) => _SectionCard(
    icon: Icons.upload_file_rounded,
    title: 'Importações CSV/OFX',
    subtitle: 'Pré-visualize antes de confirmar',
    action: IconButton.filledTonal(
      onPressed: data.wallets.isEmpty ? null : () => _pick(context),
      icon: const Icon(Icons.upload_rounded),
    ),
    child: _items(
      context,
      data.imports,
      data.wallets.isEmpty
          ? 'Crie uma carteira antes de importar.'
          : 'Nenhum extrato importado.',
      (item) =>
          '${item['filename']} · ${item['status']} · ${item['valid_rows']} válidas',
      (item) => PopupMenuButton<String>(
        onSelected: (value) {
          final id = item['id'] as int;
          if (value == 'detail') {
            _showJson(context, 'Lote de importação', api.importBatch(id));
          }
          if (value == 'preview') _preview(context, id);
          if (value == 'delete') {
            run(() => api.deleteImport(id), 'Importação excluída.');
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'detail', child: Text('Ver lote')),
          PopupMenuItem(value: 'preview', child: Text('Prévia e confirmar')),
          PopupMenuItem(value: 'delete', child: Text('Excluir')),
        ],
      ),
    ),
  );
  Future<void> _pick(BuildContext context) async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv', 'ofx'],
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final walletId = data.wallets.first['id'] as int;
    await run(() async {
      await api.uploadImport(
        walletId: walletId,
        filename: picked.name,
        bytes: bytes,
      );
    }, 'Extrato enviado para pré-visualização.');
  }

  Future<void> _preview(BuildContext context, int id) async {
    final preview = await api.importPreview(id);
    if (!context.mounted) return;
    final items = (preview['items'] as List);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prévia da importação'),
        content: SizedBox(
          width: 520,
          height: 360,
          child: ListView(
            children: [
              Text('${items.length} linhas encontradas.'),
              const SizedBox(height: 12),
              for (final row in items.take(20))
                ListTile(
                  dense: true,
                  title: Text(
                    row['description']?.toString() ?? 'Sem descrição',
                  ),
                  subtitle: Text(
                    '${row['occurred_at'] ?? ''} · ${row['status']}',
                  ),
                  trailing: Text('${row['amount'] ?? ''}'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Fechar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar importação'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await run(() async {
        await api.confirmImport(id, const {'rows': []});
      }, 'Importação confirmada.');
    }
  }
}

class _CurrencyCard extends StatefulWidget {
  const _CurrencyCard({required this.data, required this.api});
  final _ResourceData data;
  final ExpenseTrackerApi api;
  @override
  State<_CurrencyCard> createState() => _CurrencyCardState();
}

class _CurrencyCardState extends State<_CurrencyCard> {
  final amount = TextEditingController(text: '100.00');
  String base = 'BRL';
  String quote = 'USD';
  JsonMap? result;
  String? error;
  bool loading = false;

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  void _swapCurrencies() {
    setState(() {
      final previousBase = base;
      base = quote;
      quote = previousBase;
      result = null;
      error = null;
    });
  }

  Future<void> _convert() async {
    final normalizedAmount = amount.text.trim().replaceAll(',', '.');
    final parsedAmount = double.tryParse(normalizedAmount);
    if (parsedAmount == null || parsedAmount <= 0) {
      setState(() {
        result = null;
        error = 'Informe um valor maior que zero.';
      });
      return;
    }

    setState(() {
      loading = true;
      result = null;
      error = null;
    });
    try {
      final quoteResult = await widget.api.currencyQuote(
        amount: parsedAmount.toStringAsFixed(2),
        base: base,
        quote: quote,
      );
      if (mounted) setState(() => result = quoteResult);
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() {
          error = exception.statusCode == 503
              ? 'O serviço de câmbio está oscilando. Tente novamente em alguns segundos.'
              : exception.message;
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final codes = widget.data.currencies
        .map((e) => e['code'].toString())
        .toList();
    if (!codes.contains(base) && codes.isNotEmpty) base = codes.first;
    if (!codes.contains(quote) && codes.length > 1) quote = codes[1];
    return _SectionCard(
      icon: Icons.currency_exchange_rounded,
      title: 'Conversor de moedas',
      subtitle: widget.data.currencyCatalogOnline
          ? '${codes.length} moedas disponíveis'
          : '${codes.length} moedas principais · catálogo temporário',
      action: null,
      child: Column(
        children: [
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Valor'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField(
                  initialValue: base,
                  items: codes
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => base = v!),
                  decoration: const InputDecoration(labelText: 'De'),
                ),
              ),
              IconButton(
                tooltip: 'Inverter moedas',
                onPressed: _swapCurrencies,
                icon: const Icon(Icons.swap_horiz_rounded),
              ),
              Expanded(
                child: DropdownButtonFormField(
                  initialValue: quote,
                  items: codes
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => quote = v!),
                  decoration: const InputDecoration(labelText: 'Para'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading ? null : _convert,
              icon: loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.currency_exchange_rounded),
              label: Text(loading ? 'Convertendo...' : 'Converter'),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (result != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.green.withValues(alpha: .28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${result!['amount']} ${result!['base_currency']} =',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${result!['converted_amount']} ${result!['quote_currency']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Taxa: ${result!['rate']} · ${result!['effective_date']} · Frankfurter',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.data, required this.api, required this.run});
  final _ResourceData data;
  final ExpenseTrackerApi api;
  final _RunAction run;
  @override
  Widget build(BuildContext context) {
    final unread = data.alerts.where((e) => e['read_at'] == null).length;
    return _SectionCard(
      icon: Icons.notifications_active_rounded,
      title: 'Alertas de orçamento',
      subtitle: '$unread não lidos',
      action: TextButton(
        onPressed: unread == 0
            ? null
            : () => run(() async {
                await api.readAllAlerts();
              }, 'Alertas marcados como lidos.'),
        child: const Text('Ler todos'),
      ),
      child: _items(
        context,
        data.alerts,
        'Nenhum alerta de orçamento.',
        (item) =>
            '${item['alert_type']} · ${item['usage_percentage']}% do orçamento',
        (item) => item['read_at'] == null
            ? IconButton(
                tooltip: 'Marcar como lido',
                onPressed: () => run(() async {
                  await api.readAlert(item['id'] as int);
                }, 'Alerta lido.'),
                icon: const Icon(Icons.done_rounded),
              )
            : const Icon(Icons.done_all_rounded, color: AppColors.green),
      ),
    );
  }
}

class _TransactionsCard extends StatefulWidget {
  const _TransactionsCard({
    required this.data,
    required this.api,
    required this.run,
  });
  final _ResourceData data;
  final ExpenseTrackerApi api;
  final _RunAction run;
  @override
  State<_TransactionsCard> createState() => _TransactionsCardState();
}

class _TransactionsCardState extends State<_TransactionsCard> {
  int? walletId;
  Future<List<JsonMap>>? future;

  void load() {
    if (walletId == null && widget.data.wallets.isNotEmpty) {
      walletId = widget.data.wallets.first['id'] as int;
    }
    if (walletId != null) future = widget.api.transactions(walletId: walletId!);
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.receipt_long_rounded,
      title: 'Histórico de transações',
      subtitle: 'Consulte, edite ou exclua lançamentos',
      action: widget.data.wallets.isEmpty
          ? null
          : DropdownButton<int>(
              value: walletId,
              underline: const SizedBox(),
              items: widget.data.wallets
                  .map(
                    (item) => DropdownMenuItem(
                      value: item['id'] as int,
                      child: Text(item['name'].toString()),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                walletId = value;
                load();
              }),
            ),
      child: future == null
          ? const Text('Crie uma carteira para consultar transações.')
          : FutureBuilder<List<JsonMap>>(
              future: future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _items(
                  context,
                  snapshot.data!,
                  'Nenhuma transação nesta carteira.',
                  (item) =>
                      '${item['description'] ?? item['transaction_type']} · ${_money(item['amount'], item['currency'])}',
                  (item) => PopupMenuButton<String>(
                    onSelected: (value) => _selected(context, value, item),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'detail',
                        child: Text('Ver detalhes'),
                      ),
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Excluir')),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _selected(
    BuildContext context,
    String value,
    JsonMap item,
  ) async {
    final id = item['id'] as int;
    if (value == 'detail') {
      _showJson(context, 'Detalhes da transação', widget.api.transaction(id));
    }
    if (value == 'edit') {
      final description = TextEditingController(
        text: item['description']?.toString(),
      );
      final ok = await _formDialog(context, 'Editar transação', [
        TextField(
          controller: description,
          decoration: const InputDecoration(labelText: 'Descrição'),
        ),
      ]);
      if (ok) {
        await widget.run(() async {
          await widget.api.updateTransaction(id, {
            'description': description.text,
          });
        }, 'Transação atualizada.');
      }
    }
    if (value == 'delete') {
      await widget.run(
        () => widget.api.deleteTransaction(id),
        'Transação excluída.',
      );
    }
    if (mounted) setState(load);
  }
}

class _AutomationCard extends StatelessWidget {
  const _AutomationCard({
    required this.data,
    required this.api,
    required this.run,
  });

  final _ResourceData data;
  final ExpenseTrackerApi api;
  final _RunAction run;

  Future<void> _newRule(BuildContext context) async {
    if (data.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crie uma categoria antes da regra.')),
      );
      return;
    }
    final name = TextEditingController();
    final pattern = TextEditingController();
    var categoryId = data.categories.first['id'] as int;
    var matchType = 'CONTAINS';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nova regra de categorização'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nome da regra'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pattern,
                  decoration: const InputDecoration(
                    labelText: 'Texto ou expressão a encontrar',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: categoryId,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: data.categories
                      .map(
                        (item) => DropdownMenuItem(
                          value: item['id'] as int,
                          child: Text(item['name'].toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => categoryId = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: matchType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de correspondência',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'CONTAINS', child: Text('Contém')),
                    DropdownMenuItem(
                      value: 'EXACT',
                      child: Text('Texto exato'),
                    ),
                    DropdownMenuItem(
                      value: 'REGEX',
                      child: Text('Expressão regular'),
                    ),
                  ],
                  onChanged: (value) => setState(() => matchType = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Criar regra'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true) {
      await run(() async {
        await api.createCategorizationRule({
          'name': name.text.trim(),
          'pattern': pattern.text.trim(),
          'category_id': categoryId,
          'match_type': matchType,
          'priority': 100,
          'applies_to_imports': true,
        });
      }, 'Regra criada e pronta para importações.');
    }
  }

  @override
  Widget build(BuildContext context) => _SectionCard(
    icon: Icons.auto_awesome_rounded,
    title: 'Automação financeira',
    subtitle: 'Regras, assinaturas detectadas e próximos vencimentos',
    action: IconButton.filledTonal(
      onPressed: () => _newRule(context),
      icon: const Icon(Icons.add_rounded),
      tooltip: 'Nova regra',
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => run(() async {
                await api.detectSubscriptions();
              }, 'Assinaturas analisadas.'),
              icon: const Icon(Icons.manage_search_rounded),
              label: const Text('Detectar assinaturas'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => run(() async {
                await api.syncBillingAlerts();
              }, 'Alertas de cobrança atualizados.'),
              icon: const Icon(Icons.notifications_active_rounded),
              label: const Text('Atualizar vencimentos'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Regras ativas',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (data.rules.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Nenhuma regra. Crie uma para categorizar lançamentos e importações.',
            ),
          )
        else
          for (final rule in data.rules.take(6))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                rule['is_active'] == true
                    ? Icons.bolt_rounded
                    : Icons.pause_circle_outline_rounded,
                color: rule['is_active'] == true ? AppColors.primary : null,
              ),
              title: Text(
                rule['name'].toString(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('${rule['match_type']} · “${rule['pattern']}”'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  final id = rule['id'] as int;
                  if (value == 'toggle') {
                    run(
                      () async {
                        await api.updateCategorizationRule(id, {
                          'is_active': rule['is_active'] != true,
                        });
                      },
                      rule['is_active'] == true
                          ? 'Regra pausada.'
                          : 'Regra ativada.',
                    );
                  }
                  if (value == 'delete') {
                    run(
                      () => api.deleteCategorizationRule(id),
                      'Regra excluída.',
                    );
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(
                      rule['is_active'] == true ? 'Pausar' : 'Ativar',
                    ),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
              ),
            ),
        const Divider(height: 30),
        Text(
          'Assinaturas e cobranças',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (data.subscriptions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Execute a detecção após registrar ao menos três cobranças recorrentes.',
            ),
          )
        else
          for (final item in data.subscriptions.take(6))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.repeat_rounded)),
              title: Text(
                item['merchant_name'].toString(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${item['frequency']} · próximo em ${item['next_expected_date']} · confiança ${item['confidence']}%',
              ),
              trailing: Text(
                _money(item['average_amount'], item['currency']),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
        if (data.billingAlerts.isNotEmpty) ...[
          const Divider(height: 30),
          for (final alert in data.billingAlerts.take(4))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                alert['alert_type'] == 'OVERDUE'
                    ? Icons.warning_amber_rounded
                    : Icons.event_rounded,
                color: alert['alert_type'] == 'OVERDUE'
                    ? AppColors.danger
                    : AppColors.pink,
              ),
              title: Text(
                alert['alert_type'] == 'OVERDUE'
                    ? 'Cobrança possivelmente atrasada'
                    : 'Cobrança prevista em breve',
              ),
              subtitle: Text('Data esperada: ${alert['expected_date']}'),
              trailing: Text(
                _money(alert['expected_amount'], alert['currency']),
              ),
            ),
        ],
      ],
    ),
  );
}

class _PortfolioToolsCard extends StatelessWidget {
  const _PortfolioToolsCard({required this.api});
  final ExpenseTrackerApi api;

  Future<void> _download(BuildContext context) async {
    final month = DateFormat('yyyy-MM').format(DateTime.now());
    try {
      final bytes = await api.monthlyReportPdf(month);
      await FilePicker.saveFile(
        dialogTitle: 'Salvar relatório financeiro',
        fileName: 'spendly-$month.pdf',
        bytes: bytes,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relatório mensal gerado.')),
        );
      }
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => _SectionCard(
    icon: Icons.picture_as_pdf_rounded,
    title: 'Relatório para compartilhar',
    subtitle: 'Resumo mensal com receitas, despesas e categorias em PDF',
    action: null,
    child: Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.icon(
        onPressed: () => _download(context),
        icon: const Icon(Icons.download_rounded),
        label: const Text('Baixar relatório do mês'),
      ),
    ),
  );
}

Widget _items(
  BuildContext context,
  List<JsonMap> items,
  String empty,
  String Function(JsonMap) label,
  Widget Function(JsonMap) trailing,
) {
  if (items.isEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        empty,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
  return Column(
    children: [
      for (final item in items.take(6))
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            label(item),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: trailing(item),
        ),
    ],
  );
}

Future<bool> _formDialog(
  BuildContext context,
  String title,
  List<Widget> fields,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, children: fields),
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
    ) ??
    false;

Future<void> _showJson(
  BuildContext context,
  String title,
  Future<JsonMap> future,
) async {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 520,
        child: FutureBuilder<JsonMap>(
          future: future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            const encoder = JsonEncoder.withIndent('  ');
            return SelectableText(encoder.convert(snapshot.data));
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );
}

String _money(Object? value, Object? currency) {
  final parsed = double.tryParse(value?.toString() ?? '') ?? 0;
  try {
    return NumberFormat.simpleCurrency(name: currency?.toString() ?? 'BRL')
        .format(parsed);
  } catch (_) {
    return '${currency ?? ''} ${parsed.toStringAsFixed(2)}';
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.pink, size: 42),
          const SizedBox(height: 12),
          Text(
            error is ApiException
                ? (error! as ApiException).message
                : 'Não foi possível carregar os recursos.',
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    ),
  );
}
