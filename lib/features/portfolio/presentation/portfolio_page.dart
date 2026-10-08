import 'package:flutter/material.dart';
import 'package:spendlyapp/core/theme/app_colors.dart';

class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const technologies = [
      'Flutter',
      'Dart',
      'FastAPI',
      'Python',
      'PostgreSQL',
      'SQLAlchemy',
      'Alembic',
      'JWT',
      'Docker',
      'Render',
      'Neon',
      'Pytest',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre o projeto')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.purple],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 46,
                  color: Colors.white,
                ),
                const SizedBox(height: 22),
                Text(
                  'Spendly',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Uma plataforma full stack para controle, planejamento e inteligência financeira pessoal.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: .9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Arquitetura',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          const _ArchitectureFlow(),
          const SizedBox(height: 28),
          Text(
            'Tecnologias',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: technologies
                .map(
                  (item) => Chip(
                    label: Text(item),
                    avatar: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 28),
          Text(
            'Destaques de engenharia',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          const _Feature(
            icon: Icons.layers_rounded,
            title: 'Clean Architecture',
            text: 'Domínio, casos de uso, adaptadores e infraestrutura com responsabilidades separadas.',
          ),
          const _Feature(
            icon: Icons.lock_rounded,
            title: 'Segurança e isolamento',
            text: 'Autenticação JWT e todos os recursos financeiros limitados ao proprietário.',
          ),
          const _Feature(
            icon: Icons.auto_awesome_rounded,
            title: 'Automação financeira',
            text: 'Regras de categorização, importação CSV/OFX, recorrências e detecção de assinaturas.',
          ),
        ],
      ),
    );
  }
}

class _ArchitectureFlow extends StatelessWidget {
  const _ArchitectureFlow();
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Flutter', Icons.devices_rounded),
      ('REST API', Icons.api_rounded),
      ('FastAPI', Icons.bolt_rounded),
      ('PostgreSQL', Icons.storage_rounded),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(items[index].$2, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  items[index].$1,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          if (index < items.length - 1)
            const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
        ],
      ],
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: .12),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(text),
      ),
    ),
  );
}
