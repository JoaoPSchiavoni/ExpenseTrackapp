import 'package:flutter/material.dart';
import 'package:spendlyapp/app.dart';
import 'package:spendlyapp/core/api/api_client.dart';
import 'package:spendlyapp/core/api/api_config.dart';
import 'package:spendlyapp/core/api/expense_tracker_api.dart';
import 'package:spendlyapp/core/auth/session_controller.dart';
import 'package:spendlyapp/core/auth/token_store.dart';
import 'package:spendlyapp/core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = await ThemeController.load();
  final tokenStore = SecureTokenStore();
  late final SessionController session;
  final client = ApiClient(
    baseUrl: ApiConfig.baseUrl,
    accessToken: tokenStore.read,
    onUnauthorized: () => session.handleUnauthorized(),
  );
  session = SessionController(
    api: ExpenseTrackerApi(client),
    tokenStore: tokenStore,
  );
  runApp(SpendlyApp(themeController: themeController, session: session));
  session.initialize();
}
