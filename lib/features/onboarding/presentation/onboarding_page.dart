import 'package:flutter/material.dart';
import 'package:spendlyapp/core/api/api_exception.dart';
import 'package:spendlyapp/core/auth/session_controller.dart';
import 'package:spendlyapp/core/theme/app_colors.dart';
import 'package:spendlyapp/core/theme/theme_controller.dart';
import 'package:spendlyapp/core/widgets/theme_toggle.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    required this.session,
    required this.themeController,
    super.key,
  });

  final SessionController session;
  final ThemeController themeController;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  var _page = 0;

  static const _steps = [
    (
      Icons.account_balance_wallet_rounded,
      'Seu dinheiro em um só lugar',
      'Cadastre contas e acompanhe receitas, despesas e saldo sem perder o contexto.',
      AppColors.primary,
    ),
    (
      Icons.auto_awesome_rounded,
      'Automação que economiza tempo',
      'Crie regras de categoria, importe extratos e identifique assinaturas recorrentes.',
      AppColors.purple,
    ),
    (
      Icons.insights_rounded,
      'Decisões mais inteligentes',
      'Use projeções, metas, alertas e recomendações para planejar os próximos meses.',
      AppColors.green,
    ),
  ];

  Future<void> _next() async {
    if (_page < _steps.length - 1) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    try {
      await widget.session.completeOnboarding();
    } on ApiException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.session.errorMessage ?? 'Tente novamente.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                children: [
                  Text(
                    'Spendly',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  ThemeToggle(controller: widget.themeController),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _steps.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            color: step.$4.withValues(alpha: .13),
                            borderRadius: BorderRadius.circular(38),
                          ),
                          child: Icon(step.$1, size: 66, color: step.$4),
                        ),
                        const SizedBox(height: 38),
                        Text(
                          step.$2,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Text(
                            step.$3,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: index == _page ? 28 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index == _page
                        ? AppColors.primary
                        : theme.dividerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: FilledButton(
                onPressed: widget.session.submitting ? null : _next,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Text(
                  _page == _steps.length - 1 ? 'Começar agora' : 'Continuar',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
