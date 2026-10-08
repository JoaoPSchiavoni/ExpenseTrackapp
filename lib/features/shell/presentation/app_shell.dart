import 'package:flutter/material.dart';
import 'package:spendlyapp/core/auth/session_controller.dart';
import 'package:spendlyapp/core/theme/app_colors.dart';
import 'package:spendlyapp/core/theme/theme_controller.dart';
import 'package:spendlyapp/core/widgets/theme_toggle.dart';
import 'package:spendlyapp/features/budgets/presentation/budgets_page.dart';
import 'package:spendlyapp/features/dashboard/presentation/dashboard_page.dart';
import 'package:spendlyapp/features/profile/presentation/profile_page.dart';
import 'package:spendlyapp/features/resources/presentation/resources_page.dart';
import 'package:spendlyapp/features/statistics/presentation/statistics_page.dart';
import 'package:spendlyapp/features/transactions/presentation/add_transaction_sheet.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.themeController,
    required this.session,
    super.key,
  });

  final ThemeController themeController;
  final SessionController session;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _destinations = <_AppDestination>[
    _AppDestination('Início', Icons.home_rounded),
    _AppDestination('Estatísticas', Icons.bar_chart_rounded),
    _AppDestination('Orçamentos', Icons.account_balance_wallet_rounded),
    _AppDestination('Recursos', Icons.grid_view_rounded),
    _AppDestination('Perfil', Icons.person_rounded),
  ];

  Future<void> _openTransaction() async {
    final isWide = MediaQuery.sizeOf(context).width >= 760;
    if (isWide) {
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: .56),
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 520,
            child: AddTransactionSheet(api: widget.session.api),
          ),
        ),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: .94,
        child: AddTransactionSheet(api: widget.session.api),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardPage(
        themeController: widget.themeController,
        api: widget.session.api,
        user: widget.session.user,
        onAddTransaction: _openTransaction,
      ),
      StatisticsPage(
        themeController: widget.themeController,
        api: widget.session.api,
      ),
      BudgetsPage(
        themeController: widget.themeController,
        api: widget.session.api,
      ),
      ResourcesPage(
        api: widget.session.api,
        themeController: widget.themeController,
      ),
      ProfilePage(
        themeController: widget.themeController,
        session: widget.session,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 980;
        return Scaffold(
          body: Row(
            children: [
              if (isDesktop)
                _DesktopSidebar(
                  selectedIndex: _selectedIndex,
                  themeController: widget.themeController,
                  onSelected: (value) => setState(() => _selectedIndex = value),
                ),
              Expanded(
                child: KeyedSubtree(
                  key: ValueKey(_selectedIndex),
                  child: pages[_selectedIndex],
                ),
              ),
            ],
          ),
          bottomNavigationBar: isDesktop
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (value) =>
                      setState(() => _selectedIndex = value),
                  destinations: [
                    for (final destination in _destinations)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(
                          destination.icon,
                          color: AppColors.primary,
                        ),
                        label: destination.label,
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.themeController,
    required this.onSelected,
  });

  final int selectedIndex;
  final ThemeController themeController;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 244,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Brand(),
          const SizedBox(height: 38),
          for (
            var index = 0;
            index < _AppShellState._destinations.length;
            index++
          )
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SidebarItem(
                destination: _AppShellState._destinations[index],
                selected: index == selectedIndex,
                onTap: () => onSelected(index),
              ),
            ),
          const Spacer(),
          ThemeToggle(controller: themeController, showLabel: true),
          const SizedBox(height: 16),
          Text(
            'SPENDLY · PORTFÓLIO',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.3,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Spendly',
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _AppDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: .13)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(
                destination.icon,
                size: 21,
                color: selected
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? AppColors.primary : null,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

class _AppDestination {
  const _AppDestination(this.label, this.icon);

  final String label;
  final IconData icon;
}
