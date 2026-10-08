import 'package:flutter/material.dart';
import 'package:spendlyapp/core/api/api_exception.dart';
import 'package:spendlyapp/core/auth/session_controller.dart';
import 'package:spendlyapp/core/theme/app_colors.dart';
import 'package:spendlyapp/core/theme/theme_controller.dart';
import 'package:spendlyapp/core/widgets/page_header.dart';
import 'package:spendlyapp/core/widgets/theme_toggle.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    required this.themeController,
    required this.session,
    super.key,
  });
  final ThemeController themeController;
  final SessionController session;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<void> _editProfile() async {
    final user = widget.session.user!;
    final name = TextEditingController(text: user['full_name']?.toString());
    final email = TextEditingController(text: user['email']?.toString());
    final ok = await _dialog('Editar perfil', [
      TextField(
        controller: name,
        decoration: const InputDecoration(labelText: 'Nome'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: email,
        decoration: const InputDecoration(labelText: 'E-mail'),
      ),
    ]);
    if (!ok) return;
    await _run(() async {
      widget.session.user = await widget.session.api.updateMe({
        'full_name': name.text.trim(),
        'email': email.text.trim(),
      });
    }, 'Perfil atualizado.');
  }

  Future<void> _preferences() async {
    final user = widget.session.user!;
    var currency = user['base_currency']?.toString() ?? 'BRL';
    final timezone = TextEditingController(
      text: user['timezone']?.toString() ?? 'America/Sao_Paulo',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Preferências'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField(
                  initialValue: currency,
                  items: ['BRL', 'USD', 'EUR', 'GBP']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setState(() => currency = value!),
                  decoration: const InputDecoration(labelText: 'Moeda base'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timezone,
                  decoration: const InputDecoration(
                    labelText: 'Fuso horário IANA',
                  ),
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
    if (ok == true) {
      await _run(() async {
        widget.session.user = await widget.session.api.updatePreferences({
          'base_currency': currency,
          'timezone': timezone.text.trim(),
        });
      }, 'Preferências atualizadas.');
    }
  }

  Future<void> _password() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final ok = await _dialog('Alterar senha', [
      TextField(
        controller: current,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Senha atual'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: next,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Nova senha'),
      ),
    ]);
    if (ok) {
      await _run(() async {
        await widget.session.api.changePassword({
          'current_password': current.text,
          'new_password': next.text,
        });
      }, 'Senha atualizada.');
    }
  }

  Future<bool> _dialog(String title, List<Widget> fields) async =>
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

  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success)));
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: const Text(
          'Esta ação remove sua conta e não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(() async {
        await widget.session.api.deleteMe();
        await widget.session.logout();
      }, 'Conta excluída.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.session.user ?? const <String, dynamic>{};
    final name = user['full_name']?.toString().trim();
    final displayName = name == null || name.isEmpty ? 'Usuário Spendly' : name;
    final initials = displayName
        .split(RegExp(r'\s+'))
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: 'Perfil',
                  subtitle: 'Preferências e segurança da sua conta.',
                  themeController: widget.themeController,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.purple],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user['email']?.toString() ?? '',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: _editProfile,
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _SettingTile(
                          icon: Icons.palette_outlined,
                          color: AppColors.purple,
                          title: 'Aparência',
                          subtitle: widget.themeController.isDark
                              ? 'Tema escuro'
                              : 'Tema claro',
                          trailing: ThemeToggle(
                            controller: widget.themeController,
                          ),
                        ),
                        const Divider(height: 24),
                        _SettingTile(
                          icon: Icons.tune_rounded,
                          color: AppColors.green,
                          title: 'Moeda e fuso horário',
                          subtitle:
                              '${user['base_currency'] ?? 'BRL'} · ${user['timezone'] ?? 'UTC'}',
                          onTap: _preferences,
                        ),
                        const Divider(height: 24),
                        _SettingTile(
                          icon: Icons.lock_outline_rounded,
                          color: AppColors.amber,
                          title: 'Alterar senha',
                          subtitle: 'Proteja sua conta',
                          onTap: _password,
                        ),
                        const Divider(height: 24),
                        _SettingTile(
                          icon: Icons.logout_rounded,
                          color: AppColors.primary,
                          title: 'Sair',
                          subtitle: 'Encerrar esta sessão',
                          onTap: widget.session.logout,
                        ),
                        const Divider(height: 24),
                        _SettingTile(
                          icon: Icons.delete_forever_outlined,
                          color: AppColors.danger,
                          title: 'Excluir conta',
                          subtitle: 'Remover permanentemente seus dados',
                          onTap: _deleteAccount,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
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
            trailing ?? const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
