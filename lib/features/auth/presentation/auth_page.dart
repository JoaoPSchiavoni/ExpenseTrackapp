import 'package:flutter/material.dart';
import 'package:spendlyapp/core/api/api_exception.dart';
import 'package:spendlyapp/core/auth/session_controller.dart';
import 'package:spendlyapp/core/theme/app_colors.dart';
import 'package:spendlyapp/core/theme/theme_controller.dart';
import 'package:spendlyapp/core/widgets/theme_toggle.dart';
import 'package:spendlyapp/features/portfolio/presentation/portfolio_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({
    required this.session,
    required this.themeController,
    super.key,
  });

  final SessionController session;
  final ThemeController themeController;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      if (_register) {
        await widget.session.register(
          name: _name.text,
          email: _email.text,
          password: _password.text,
        );
      } else {
        await widget.session.login(
          email: _email.text,
          password: _password.text,
        );
      }
    } on ApiException {
      // The controller exposes a user-friendly message below the form.
    } catch (_) {}
  }

  Future<void> _startDemo() async {
    try {
      await widget.session.startDemo();
    } on ApiException {
      // The controller exposes a user-friendly message below the form.
    } catch (_) {}
  }

  void _openPortfolio() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const PortfolioPage()));
  }

  void _toggleMode() {
    setState(() {
      _register = !_register;
      _obscure = true;
      widget.session.errorMessage = null;
      _formKey.currentState?.reset();
    });
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    final lineColor = theme.colorScheme.onSurface.withValues(alpha: .42);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: theme.colorScheme.onSurfaceVariant,
        fontSize: 16,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
      filled: false,
      contentPadding: const EdgeInsets.fromLTRB(0, 11, 0, 10),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: lineColor, width: 1.5),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: lineColor, width: 1.5),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.danger, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : const Color(0xFFF0F1F4),
          gradient: RadialGradient(
            center: const Alignment(-.8, -.9),
            radius: 1.25,
            colors: [
              AppColors.primary.withValues(alpha: isDark ? .16 : .10),
              isDark ? AppColors.darkBackground : const Color(0xFFF0F1F4),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 680;
              final panelHeight = constraints.maxHeight - (desktop ? 84 : 0);
              return Center(
                child: Container(
                  width: desktop ? 490 : double.infinity,
                  margin: desktop
                      ? const EdgeInsets.symmetric(horizontal: 24, vertical: 42)
                      : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(desktop ? 34 : 0),
                    border: desktop
                        ? Border.all(color: theme.dividerColor)
                        : null,
                    boxShadow: desktop
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? .30 : .08,
                              ),
                              blurRadius: 38,
                              offset: const Offset(0, 18),
                            ),
                          ]
                        : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: panelHeight),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            desktop ? 56 : 30,
                            20,
                            desktop ? 56 : 30,
                            28,
                          ),
                          child: AutofillGroup(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ThemeToggle(
                                      controller: widget.themeController,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const _SpendlyMark(),
                                  const SizedBox(height: 32),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    child: Column(
                                      key: ValueKey(_register),
                                      children: [
                                        Text(
                                          _register
                                              ? 'Crie sua conta'
                                              : 'Bem-vindo de volta!',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.headlineMedium
                                              ?.copyWith(
                                                fontSize: desktop ? 34 : 31,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -1.1,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _register
                                              ? 'Organize sua vida financeira em um só lugar.'
                                              : 'Entre com seus dados para continuar.',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: _register ? 36 : 48),
                                  if (_register) ...[
                                    TextFormField(
                                      key: const ValueKey('auth-name'),
                                      controller: _name,
                                      autofillHints: const [AutofillHints.name],
                                      textCapitalization:
                                          TextCapitalization.words,
                                      textInputAction: TextInputAction.next,
                                      style: const TextStyle(fontSize: 17),
                                      decoration: _fieldDecoration(
                                        context,
                                        label: 'Nome',
                                      ),
                                      validator: (value) =>
                                          value == null || value.trim().isEmpty
                                          ? 'Informe seu nome'
                                          : null,
                                    ),
                                    const SizedBox(height: 18),
                                  ],
                                  TextFormField(
                                    key: const ValueKey('auth-email'),
                                    controller: _email,
                                    autofillHints: const [
                                      AutofillHints.username,
                                      AutofillHints.email,
                                    ],
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    style: const TextStyle(fontSize: 17),
                                    decoration: _fieldDecoration(
                                      context,
                                      label: 'E-mail',
                                    ),
                                    validator: (value) =>
                                        value == null || !value.contains('@')
                                        ? 'Informe um e-mail válido'
                                        : null,
                                  ),
                                  const SizedBox(height: 18),
                                  TextFormField(
                                    key: const ValueKey('auth-password'),
                                    controller: _password,
                                    autofillHints: [
                                      _register
                                          ? AutofillHints.newPassword
                                          : AutofillHints.password,
                                    ],
                                    obscureText: _obscure,
                                    onFieldSubmitted: (_) => _submit(),
                                    style: const TextStyle(fontSize: 17),
                                    decoration: _fieldDecoration(
                                      context,
                                      label: 'Senha',
                                      suffixIcon: IconButton(
                                        tooltip: _obscure
                                            ? 'Mostrar senha'
                                            : 'Ocultar senha',
                                        onPressed: () => setState(
                                          () => _obscure = !_obscure,
                                        ),
                                        icon: Icon(
                                          _obscure
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 21,
                                        ),
                                      ),
                                    ),
                                    validator: (value) =>
                                        value == null || value.length < 8
                                        ? 'Use pelo menos 8 caracteres'
                                        : null,
                                  ),
                                  if (widget.session.errorMessage != null) ...[
                                    const SizedBox(height: 18),
                                    Container(
                                      key: const ValueKey('auth-error'),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.danger.withValues(
                                          alpha: .10,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.error_outline_rounded,
                                            color: AppColors.danger,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              widget.session.errorMessage!,
                                              style: const TextStyle(
                                                color: AppColors.danger,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 32),
                                  FilledButton(
                                    key: const ValueKey('auth-submit'),
                                    onPressed: widget.session.submitting
                                        ? null
                                        : _submit,
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(58),
                                      backgroundColor: isDark
                                          ? Colors.white
                                          : AppColors.ink,
                                      foregroundColor: isDark
                                          ? AppColors.ink
                                          : Colors.white,
                                      disabledBackgroundColor: theme
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: .18),
                                      shape: const StadiumBorder(),
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    child: widget.session.submitting
                                        ? SizedBox.square(
                                            dimension: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: isDark
                                                  ? AppColors.ink
                                                  : Colors.white,
                                            ),
                                          )
                                        : Text(
                                            _register
                                                ? 'Criar conta'
                                                : 'Entrar',
                                          ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    key: const ValueKey('auth-demo'),
                                    onPressed: widget.session.submitting
                                        ? null
                                        : _startDemo,
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(54),
                                      shape: const StadiumBorder(),
                                    ),
                                    icon: const Icon(
                                      Icons.auto_awesome_rounded,
                                    ),
                                    label: const Text('Explorar demonstração'),
                                  ),
                                  TextButton.icon(
                                    onPressed: _openPortfolio,
                                    icon: const Icon(
                                      Icons.architecture_rounded,
                                      size: 19,
                                    ),
                                    label: const Text(
                                      'Conhecer arquitetura e tecnologias',
                                    ),
                                  ),
                                  const Spacer(),
                                  const SizedBox(height: 18),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        _register
                                            ? 'Já possui uma conta?'
                                            : 'Ainda não possui uma conta?',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      TextButton(
                                        key: const ValueKey('auth-mode-toggle'),
                                        onPressed: widget.session.submitting
                                            ? null
                                            : _toggleMode,
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              theme.colorScheme.onSurface,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 4,
                                          ),
                                          textStyle: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        child: Text(
                                          _register ? 'Entrar' : 'Criar conta',
                                        ),
                                      ),
                                    ],
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
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SpendlyMark extends StatelessWidget {
  const _SpendlyMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .28),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Icon(
          Icons.account_balance_wallet_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
