import 'package:flutter/material.dart';
import 'package:spendlyapp/core/theme/app_theme.dart';
import 'package:spendlyapp/core/theme/theme_controller.dart';
import 'package:spendlyapp/core/auth/session_controller.dart';
import 'package:spendlyapp/features/auth/presentation/app_gate.dart';

class SpendlyApp extends StatelessWidget {
  const SpendlyApp({
    required this.themeController,
    required this.session,
    super.key,
  });

  final ThemeController themeController;
  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Spendly',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.mode,
          home: AppGate(session: session, themeController: themeController),
        );
      },
    );
  }
}
