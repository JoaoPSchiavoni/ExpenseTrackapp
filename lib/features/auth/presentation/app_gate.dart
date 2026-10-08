import 'package:flutter/material.dart';
import 'package:spendlyapp/core/auth/session_controller.dart';
import 'package:spendlyapp/core/theme/app_colors.dart';
import 'package:spendlyapp/core/theme/theme_controller.dart';
import 'package:spendlyapp/core/widgets/theme_toggle.dart';
import 'package:spendlyapp/features/auth/presentation/auth_page.dart';
import 'package:spendlyapp/features/shell/presentation/app_shell.dart';
import 'package:spendlyapp/features/onboarding/presentation/onboarding_page.dart';

class AppGate extends StatelessWidget {
  const AppGate({
    required this.session,
    required this.themeController,
    super.key,
  });

  final SessionController session;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => switch (session.status) {
        SessionStatus.booting => _StartupPage(themeController: themeController),
        SessionStatus.unavailable => _UnavailablePage(
          themeController: themeController,
          message: session.errorMessage,
          onRetry: session.initialize,
        ),
        SessionStatus.unauthenticated => AuthPage(
          session: session,
          themeController: themeController,
        ),
        SessionStatus.authenticated =>
          session.user?['onboarding_completed'] == false
              ? OnboardingPage(
                  session: session,
                  themeController: themeController,
                )
              : AppShell(session: session, themeController: themeController),
      },
    );
  }
}

class _StartupPage extends StatelessWidget {
  const _StartupPage({required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          const _AuthBackdrop(),
          Positioned(
            top: 20,
            right: 20,
            child: SafeArea(child: ThemeToggle(controller: themeController)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Logo(size: 76),
                  const SizedBox(height: 26),
                  Text(
                    'Preparando seu espaço financeiro…',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No plano gratuito, o servidor pode levar alguns segundos para acordar.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailablePage extends StatelessWidget {
  const _UnavailablePage({
    required this.themeController,
    required this.message,
    required this.onRetry,
  });

  final ThemeController themeController;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _AuthBackdrop(),
          Positioned(
            top: 20,
            right: 20,
            child: SafeArea(child: ThemeToggle(controller: themeController)),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 54,
                      color: AppColors.pink,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Servidor descansando',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message ?? 'Tente novamente.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: .13),
            Theme.of(context).scaffoldBackgroundColor,
            AppColors.purple.withValues(alpha: .08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({this.size = 58});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.purple],
        ),
        borderRadius: BorderRadius.circular(size * .3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .28),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(Icons.bolt_rounded, color: Colors.white, size: size * .55),
    );
  }
}
