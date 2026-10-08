import 'package:flutter/material.dart';
import 'package:spendlyapp/core/theme/app_colors.dart';
import 'package:spendlyapp/core/theme/theme_controller.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({
    required this.controller,
    this.showLabel = false,
    super.key,
  });

  final ThemeController controller;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = controller.isDark;
    final label = isDark ? 'Tema claro' : 'Tema escuro';
    final icon = isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded;

    return Tooltip(
      message: label,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: const ValueKey('theme-toggle'),
          onTap: controller.toggle,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 46,
            padding: EdgeInsets.symmetric(horizontal: showLabel ? 14 : 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => RotationTransition(
                    turns: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    icon,
                    key: ValueKey(isDark),
                    size: 20,
                    color: isDark ? AppColors.amber : AppColors.primary,
                  ),
                ),
                if (showLabel) ...[
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
