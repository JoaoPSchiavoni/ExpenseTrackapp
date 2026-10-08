import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spendlyapp/core/api/api_exception.dart';
import 'package:spendlyapp/core/api/expense_tracker_api.dart';
import 'package:spendlyapp/core/theme/app_colors.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({required this.api, super.key});

  final ExpenseTrackerApi api;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  late Future<List<List<JsonMap>>> _options;
  bool _isExpense = true;
  bool _saving = false;
  int? _walletId;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _options = Future.wait([widget.api.wallets(), widget.api.categories()]);
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0 || _walletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _walletId == null
                ? 'Crie ou selecione uma carteira.'
                : 'Informe um valor válido.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.api.createTransaction({
        'wallet_id': _walletId,
        'amount': amount.toStringAsFixed(2),
        'transaction_type': _isExpense ? 'EXPENSE' : 'INCOME',
        if (_categoryId != null) 'category_id': _categoryId,
        if (_description.text.trim().isNotEmpty)
          'description': _description.text.trim(),
      });
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isExpense
                ? 'Despesa salva com sucesso.'
                : 'Receita salva com sucesso.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
                const Expanded(
                  child: Text(
                    'Nova transação',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Expanded(
            child: FutureBuilder<List<List<JsonMap>>>(
              future: _options,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final wallets = snapshot.data![0];
                final categories = snapshot.data![1];
                _walletId ??= wallets.isEmpty
                    ? null
                    : wallets.first['id'] as int;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TransactionTypeSwitch(
                        isExpense: _isExpense,
                        onChanged: (value) =>
                            setState(() => _isExpense = value),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 25,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _isExpense
                                  ? 'VALOR DA DESPESA'
                                  : 'VALOR DA RECEITA',
                              style: theme.textTheme.labelSmall?.copyWith(
                                letterSpacing: 1.2,
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'R\$',
                                  style: TextStyle(
                                    color: _isExpense
                                        ? AppColors.primary
                                        : AppColors.green,
                                    fontSize: 27,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: IntrinsicWidth(
                                    child: TextField(
                                      key: const ValueKey('transaction-amount'),
                                      controller: _amount,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[0-9,.]'),
                                        ),
                                      ],
                                      style: const TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: '0,00',
                                        filled: false,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<int>(
                        initialValue: _walletId,
                        decoration: const InputDecoration(
                          labelText: 'Carteira',
                          prefixIcon: Icon(
                            Icons.account_balance_wallet_outlined,
                          ),
                        ),
                        items: wallets
                            .map(
                              (wallet) => DropdownMenuItem(
                                value: wallet['id'] as int,
                                child: Text(
                                  '${wallet['name']} · ${wallet['currency']}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _walletId = value),
                      ),
                      if (wallets.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Cadastre uma carteira na Central financeira.',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text(
                        'CATEGORIA',
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (categories.isEmpty)
                        const Text(
                          'Sem categorias. O lançamento pode ser salvo sem categoria.',
                        )
                      else
                        Wrap(
                          spacing: 9,
                          runSpacing: 9,
                          children: [
                            for (
                              var index = 0;
                              index < categories.length;
                              index++
                            )
                              ChoiceChip(
                                selected:
                                    _categoryId == categories[index]['id'],
                                onSelected: (_) => setState(
                                  () => _categoryId =
                                      categories[index]['id'] as int,
                                ),
                                avatar: Icon(_categoryIcon(index), size: 17),
                                label: Text(
                                  categories[index]['name'].toString(),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _description,
                        decoration: const InputDecoration(
                          hintText: 'Descrição da transação',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailTile(
                        icon: Icons.calendar_today_rounded,
                        title:
                            'Hoje, ${MaterialLocalizations.of(context).formatCompactDate(DateTime.now())}',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
            child: FilledButton(
              key: const ValueKey('save-transaction'),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Salvar transação'),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _categoryIcon(int index) => const [
  Icons.restaurant_rounded,
  Icons.directions_car_rounded,
  Icons.shopping_bag_rounded,
  Icons.receipt_long_rounded,
  Icons.sports_esports_rounded,
  Icons.favorite_rounded,
  Icons.home_rounded,
  Icons.more_horiz_rounded,
][index % 8];

class _TransactionTypeSwitch extends StatelessWidget {
  const _TransactionTypeSwitch({
    required this.isExpense,
    required this.onChanged,
  });
  final bool isExpense;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Row(
      children: [
        Expanded(
          child: _TypeButton(
            label: 'Despesa',
            selected: isExpense,
            onTap: () => onChanged(true),
          ),
        ),
        Expanded(
          child: _TypeButton(
            label: 'Receita',
            selected: !isExpense,
            onTap: () => onChanged(false),
          ),
        ),
      ],
    ),
  );
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(13),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected
              ? Colors.white
              : Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
