import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:spendlyapp/core/theme/app_colors.dart';

class BalanceHeroCard extends StatelessWidget {
  const BalanceHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                'Saldo total',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .78),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'BRL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'R\$ 12.845,50',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.4,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const Expanded(
                child: _HeroMetric(
                  icon: Icons.south_west_rounded,
                  label: 'RECEITAS',
                  value: 'R\$ 8.500',
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: Colors.white.withValues(alpha: .2),
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: _HeroMetric(
                    icon: Icons.north_east_rounded,
                    label: 'DESPESAS',
                    value: 'R\$ 3.245',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: Colors.white.withValues(alpha: .8)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .72),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: .5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class CashFlowCard extends StatelessWidget {
  const CashFlowCard({super.key});

  static const _income = [.32, .48, .4, .7, .58, .82];
  static const _expense = [.2, .3, .5, .34, .62, .44];
  static const _months = ['MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        constraints: const BoxConstraints(minHeight: 254),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fluxo de caixa',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Últimos 6 meses',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const _LegendDot(color: AppColors.primary, label: 'Receitas'),
                const SizedBox(width: 12),
                const _LegendDot(color: AppColors.pink, label: 'Despesas'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 154,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var index = 0; index < _months.length; index++)
                    Expanded(
                      child: _BarGroup(
                        label: _months[index],
                        income: _income[index],
                        expense: _expense[index],
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

class _BarGroup extends StatelessWidget {
  const _BarGroup({
    required this.label,
    required this.income,
    required this.expense,
  });

  final String label;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _AnimatedBar(value: income, color: AppColors.primary),
              const SizedBox(width: 4),
              _AnimatedBar(value: expense, color: AppColors.pink),
            ],
          ),
        ),
        const SizedBox(height: 9),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AnimatedBar extends StatelessWidget {
  const _AnimatedBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 9,
          height: constraints.maxHeight * value,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class InsightBanner extends StatelessWidget {
  const InsightBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(height: 1.45),
                children: const [
                  TextSpan(
                    text: 'Boa notícia! ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: 'Você gastou '),
                  TextSpan(
                    text: '12% menos',
                    style: TextStyle(
                      color: AppColors.green,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(text: ' com alimentação neste mês.'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, size: 15),
        ],
      ),
    );
  }
}

class SpendingCard extends StatelessWidget {
  const SpendingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Gastos por categoria',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(onPressed: () {}, child: const Text('Detalhes')),
              ],
            ),
            const SizedBox(height: 18),
            const Center(
              child: SizedBox(
                width: 190,
                height: 190,
                child: CustomPaint(
                  painter: SpendingDonutPainter(),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'R\$ 3,2 mil',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'GASTOS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Wrap(
              runSpacing: 12,
              spacing: 18,
              children: [
                _CategoryLegend(
                  color: AppColors.green,
                  label: 'Alimentação',
                  value: '35%',
                ),
                _CategoryLegend(
                  color: AppColors.amber,
                  label: 'Transporte',
                  value: '28%',
                ),
                _CategoryLegend(
                  color: AppColors.pink,
                  label: 'Compras',
                  value: '21%',
                ),
                _CategoryLegend(
                  color: AppColors.primary,
                  label: 'Contas',
                  value: '16%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SpendingDonutPainter extends CustomPainter {
  const SpendingDonutPainter();

  static const values = [.35, .28, .21, .16];
  static const colors = [
    AppColors.green,
    AppColors.amber,
    AppColors.pink,
    AppColors.primary,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    var startAngle = -math.pi / 2;
    const gap = .035;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 23
      ..strokeCap = StrokeCap.butt;
    for (var index = 0; index < values.length; index++) {
      final sweep = math.pi * 2 * values[index];
      paint.color = colors[index];
      canvas.drawArc(
        rect.deflate(14),
        startAngle + gap,
        sweep - gap * 2,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CategoryLegend extends StatelessWidget {
  const _CategoryLegend({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Orçamentos',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Acompanhe seus limites mensais',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _BudgetRow(
              icon: Icons.restaurant_rounded,
              color: AppColors.amber,
              label: 'Alimentação',
              value: 'R\$ 680 de R\$ 900',
              progress: .76,
            ),
            const SizedBox(height: 18),
            const _BudgetRow(
              icon: Icons.directions_car_filled_rounded,
              color: AppColors.primary,
              label: 'Transporte',
              value: 'R\$ 310 de R\$ 600',
              progress: .52,
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.progress,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  color: color,
                  backgroundColor: color.withValues(alpha: .12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Transações recentes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(onPressed: () {}, child: const Text('Ver todas')),
              ],
            ),
            const SizedBox(height: 8),
            const _TransactionRow(
              icon: Icons.shopping_bag_rounded,
              color: AppColors.pink,
              title: 'Mercado Central',
              subtitle: 'Alimentação · Hoje',
              amount: '- R\$ 184,90',
            ),
            const Divider(height: 1),
            const _TransactionRow(
              icon: Icons.payments_rounded,
              color: AppColors.green,
              title: 'Salário',
              subtitle: 'Receita · Ontem',
              amount: '+ R\$ 5.800,00',
              income: true,
            ),
            const Divider(height: 1),
            const _TransactionRow(
              icon: Icons.local_gas_station_rounded,
              color: AppColors.primary,
              title: 'Posto Avenida',
              subtitle: 'Transporte · 02 Out',
              amount: '- R\$ 220,00',
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.income = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String amount;
  final bool income;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: income ? AppColors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}
