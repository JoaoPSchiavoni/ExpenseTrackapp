import 'dart:convert';
import 'dart:typed_data';

import 'package:spendlyapp/core/api/api_client.dart';

class ApiOperation {
  const ApiOperation(this.method, this.path);

  final String method;
  final String path;

  String get key => '$method $path';
}

typedef JsonMap = Map<String, dynamic>;

class ExpenseTrackerApi {
  const ExpenseTrackerApi(this.client);

  final ApiClient client;

  static const supportedOperations = <ApiOperation>[
    ApiOperation('POST', '/api/v1/auth/register'),
    ApiOperation('POST', '/api/v1/auth/login'),
    ApiOperation('POST', '/api/v1/auth/demo-session'),
    ApiOperation('GET', '/api/v1/users/me'),
    ApiOperation('PUT', '/api/v1/users/me'),
    ApiOperation('DELETE', '/api/v1/users/me'),
    ApiOperation('POST', '/api/v1/users/me/password'),
    ApiOperation('PATCH', '/api/v1/users/me/preferences'),
    ApiOperation('GET', '/api/v1/wallets/'),
    ApiOperation('POST', '/api/v1/wallets/'),
    ApiOperation('GET', '/api/v1/wallets/{id}'),
    ApiOperation('PUT', '/api/v1/wallets/{id}'),
    ApiOperation('DELETE', '/api/v1/wallets/{id}'),
    ApiOperation('GET', '/api/v1/categories/'),
    ApiOperation('POST', '/api/v1/categories/'),
    ApiOperation('GET', '/api/v1/categories/{id}'),
    ApiOperation('PUT', '/api/v1/categories/{id}'),
    ApiOperation('DELETE', '/api/v1/categories/{id}'),
    ApiOperation('GET', '/api/v1/currencies/'),
    ApiOperation('GET', '/api/v1/currencies/quote'),
    ApiOperation('GET', '/api/v1/dashboard/overview'),
    ApiOperation('GET', '/api/v1/dashboard/cash-flow'),
    ApiOperation('GET', '/api/v1/dashboard/spending-by-category'),
    ApiOperation('GET', '/api/v1/dashboard/recent-transactions'),
    ApiOperation('GET', '/api/v1/dashboard/balance-projection'),
    ApiOperation('GET', '/api/v1/dashboard/period-comparison'),
    ApiOperation('GET', '/api/v1/dashboard/financial-health'),
    ApiOperation('GET', '/api/v1/dashboard/recommendations'),
    ApiOperation('POST', '/api/v1/imports/'),
    ApiOperation('GET', '/api/v1/imports/'),
    ApiOperation('GET', '/api/v1/imports/{batch_id}'),
    ApiOperation('DELETE', '/api/v1/imports/{batch_id}'),
    ApiOperation('GET', '/api/v1/imports/{batch_id}/preview'),
    ApiOperation('POST', '/api/v1/imports/{batch_id}/confirm'),
    ApiOperation('POST', '/api/v1/goals/'),
    ApiOperation('GET', '/api/v1/goals/'),
    ApiOperation('GET', '/api/v1/goals/{id}'),
    ApiOperation('PUT', '/api/v1/goals/{id}'),
    ApiOperation('DELETE', '/api/v1/goals/{id}'),
    ApiOperation('POST', '/api/v1/goals/{id}/contributions'),
    ApiOperation('GET', '/api/v1/goals/{id}/contributions'),
    ApiOperation(
      'DELETE',
      '/api/v1/goals/{id}/contributions/{contribution_id}',
    ),
    ApiOperation('GET', '/api/v1/budget-alerts/'),
    ApiOperation('GET', '/api/v1/budget-alerts/unread-count'),
    ApiOperation('POST', '/api/v1/budget-alerts/read-all'),
    ApiOperation('PATCH', '/api/v1/budget-alerts/{id}/read'),
    ApiOperation('GET', '/api/v1/recurring-transactions/'),
    ApiOperation('POST', '/api/v1/recurring-transactions/'),
    ApiOperation('GET', '/api/v1/recurring-transactions/{id}'),
    ApiOperation('PUT', '/api/v1/recurring-transactions/{id}'),
    ApiOperation('DELETE', '/api/v1/recurring-transactions/{id}'),
    ApiOperation('POST', '/api/v1/recurring-transactions/process-due'),
    ApiOperation('POST', '/api/v1/transactions/'),
    ApiOperation('GET', '/api/v1/transactions/'),
    ApiOperation('POST', '/api/v1/transactions/bulk'),
    ApiOperation('GET', '/api/v1/transactions/{id}'),
    ApiOperation('PUT', '/api/v1/transactions/{id}'),
    ApiOperation('DELETE', '/api/v1/transactions/{id}'),
    ApiOperation('GET', '/api/v1/budgets/'),
    ApiOperation('POST', '/api/v1/budgets/'),
    ApiOperation('GET', '/api/v1/budgets/status'),
    ApiOperation('GET', '/api/v1/budgets/{id}'),
    ApiOperation('PUT', '/api/v1/budgets/{id}'),
    ApiOperation('DELETE', '/api/v1/budgets/{id}'),
    ApiOperation('GET', '/api/v1/budgets/{id}/status'),
    ApiOperation('GET', '/api/v1/reports/monthly'),
    ApiOperation('GET', '/api/v1/reports/category-summary'),
    ApiOperation('GET', '/api/v1/reports/monthly.pdf'),
    ApiOperation('POST', '/api/v1/automation/rules'),
    ApiOperation('GET', '/api/v1/automation/rules'),
    ApiOperation('POST', '/api/v1/automation/rules/test-match'),
    ApiOperation('PUT', '/api/v1/automation/rules/{id}'),
    ApiOperation('DELETE', '/api/v1/automation/rules/{id}'),
    ApiOperation('POST', '/api/v1/automation/subscriptions/detect'),
    ApiOperation('GET', '/api/v1/automation/subscriptions'),
    ApiOperation('PATCH', '/api/v1/automation/subscriptions/{id}'),
    ApiOperation('POST', '/api/v1/automation/billing-alerts/sync'),
    ApiOperation('GET', '/api/v1/automation/billing-alerts'),
    ApiOperation('PATCH', '/api/v1/automation/billing-alerts/{id}/read'),
    ApiOperation('GET', '/health'),
  ];

  JsonMap _map(dynamic value) => Map<String, dynamic>.from(value as Map);
  List<JsonMap> _list(dynamic value) => (value as List)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();

  Future<JsonMap> health({Duration? timeout}) async => _map(
    await client.get(
      '/health',
      authenticated: false,
      timeout: timeout ?? const Duration(seconds: 30),
    ),
  );
  Future<JsonMap> register({
    required String email,
    required String password,
    String? fullName,
  }) async => _map(
    await client.post(
      '/api/v1/auth/register',
      authenticated: false,
      body: {
        'email': email,
        'password': password,
        if (fullName?.isNotEmpty == true) 'full_name': fullName,
      },
    ),
  );
  Future<JsonMap> login(String email, String password) async => _map(
    await client.post(
      '/api/v1/auth/login',
      authenticated: false,
      body: {'email': email, 'password': password},
    ),
  );
  Future<JsonMap> demoSession() async => _map(
    await client.post('/api/v1/auth/demo-session', authenticated: false),
  );

  Future<JsonMap> getMe() async => _map(await client.get('/api/v1/users/me'));
  Future<JsonMap> updateMe(JsonMap body) async =>
      _map(await client.put('/api/v1/users/me', body: body));
  Future<void> deleteMe() async => client.delete('/api/v1/users/me');
  Future<void> changePassword(JsonMap body) async =>
      client.post('/api/v1/users/me/password', body: body);
  Future<JsonMap> updatePreferences(JsonMap body) async =>
      _map(await client.patch('/api/v1/users/me/preferences', body: body));

  Future<List<JsonMap>> wallets() async =>
      _list(await client.get('/api/v1/wallets/'));
  Future<JsonMap> createWallet(JsonMap body) async =>
      _map(await client.post('/api/v1/wallets/', body: body));
  Future<JsonMap> wallet(int id) async =>
      _map(await client.get('/api/v1/wallets/$id'));
  Future<JsonMap> updateWallet(int id, JsonMap body) async =>
      _map(await client.put('/api/v1/wallets/$id', body: body));
  Future<void> deleteWallet(int id) async =>
      client.delete('/api/v1/wallets/$id');

  Future<List<JsonMap>> categories() async =>
      _list(await client.get('/api/v1/categories/'));
  Future<JsonMap> createCategory(JsonMap body) async =>
      _map(await client.post('/api/v1/categories/', body: body));
  Future<JsonMap> category(int id) async =>
      _map(await client.get('/api/v1/categories/$id'));
  Future<JsonMap> updateCategory(int id, JsonMap body) async =>
      _map(await client.put('/api/v1/categories/$id', body: body));
  Future<void> deleteCategory(int id) async =>
      client.delete('/api/v1/categories/$id');

  Future<List<JsonMap>> currencies() async =>
      _list(await client.get('/api/v1/currencies/'));
  Future<JsonMap> currencyQuote({
    required String amount,
    required String base,
    required String quote,
    String? date,
  }) async => _map(
    await client.get(
      '/api/v1/currencies/quote',
      query: {
        'amount': amount,
        'base_currency': base,
        'quote_currency': quote,
        'date': date,
      },
    ),
  );

  Future<JsonMap> dashboardOverview({String? month}) async => _map(
    await client.get('/api/v1/dashboard/overview', query: {'month': month}),
  );
  Future<JsonMap> dashboardCashFlow({int months = 6}) async => _map(
    await client.get('/api/v1/dashboard/cash-flow', query: {'months': months}),
  );
  Future<JsonMap> dashboardSpending({String? month, int limit = 8}) async =>
      _map(
        await client.get(
          '/api/v1/dashboard/spending-by-category',
          query: {'month': month, 'limit': limit},
        ),
      );
  Future<List<JsonMap>> dashboardRecent({int limit = 5}) async => _list(
    await client.get(
      '/api/v1/dashboard/recent-transactions',
      query: {'limit': limit},
    ),
  );
  Future<JsonMap> balanceProjection({int months = 6}) async => _map(
    await client.get(
      '/api/v1/dashboard/balance-projection',
      query: {'months': months},
    ),
  );
  Future<JsonMap> periodComparison({String? month}) async => _map(
    await client.get(
      '/api/v1/dashboard/period-comparison',
      query: {'month': month},
    ),
  );
  Future<JsonMap> financialHealth({String? month}) async => _map(
    await client.get(
      '/api/v1/dashboard/financial-health',
      query: {'month': month},
    ),
  );
  Future<List<JsonMap>> financialRecommendations({String? month}) async =>
      _list(
        await client.get(
          '/api/v1/dashboard/recommendations',
          query: {'month': month},
        ),
      );

  Future<List<JsonMap>> recurringTransactions() async =>
      _list(await client.get('/api/v1/recurring-transactions/'));
  Future<JsonMap> createRecurringTransaction(JsonMap body) async =>
      _map(await client.post('/api/v1/recurring-transactions/', body: body));
  Future<JsonMap> recurringTransaction(int id) async =>
      _map(await client.get('/api/v1/recurring-transactions/$id'));
  Future<JsonMap> updateRecurringTransaction(int id, JsonMap body) async =>
      _map(await client.put('/api/v1/recurring-transactions/$id', body: body));
  Future<void> deleteRecurringTransaction(int id) async =>
      client.delete('/api/v1/recurring-transactions/$id');
  Future<JsonMap> processDueRecurringTransactions() async =>
      _map(await client.post('/api/v1/recurring-transactions/process-due'));

  Future<JsonMap> uploadImport({
    required int walletId,
    required String filename,
    required Uint8List bytes,
    Map<String, String>? options,
  }) async => _map(
    await client.multipart(
      '/api/v1/imports/',
      fields: {
        'wallet_id': '$walletId',
        if (options != null) 'options': jsonEncode(options),
      },
      filename: filename,
      bytes: bytes,
    ),
  );
  Future<List<JsonMap>> imports({int limit = 50, int offset = 0}) async =>
      _list(
        await client.get(
          '/api/v1/imports/',
          query: {'limit': limit, 'offset': offset},
        ),
      );
  Future<JsonMap> importBatch(int id) async =>
      _map(await client.get('/api/v1/imports/$id'));
  Future<JsonMap> importPreview(int id) async =>
      _map(await client.get('/api/v1/imports/$id/preview'));
  Future<JsonMap> confirmImport(int id, JsonMap body) async =>
      _map(await client.post('/api/v1/imports/$id/confirm', body: body));
  Future<void> deleteImport(int id) async =>
      client.delete('/api/v1/imports/$id');

  Future<List<JsonMap>> goals() async =>
      _list(await client.get('/api/v1/goals/'));
  Future<JsonMap> createGoal(JsonMap body) async =>
      _map(await client.post('/api/v1/goals/', body: body));
  Future<JsonMap> goal(int id) async =>
      _map(await client.get('/api/v1/goals/$id'));
  Future<JsonMap> updateGoal(int id, JsonMap body) async =>
      _map(await client.put('/api/v1/goals/$id', body: body));
  Future<void> deleteGoal(int id) async => client.delete('/api/v1/goals/$id');
  Future<JsonMap> addContribution(int id, JsonMap body) async =>
      _map(await client.post('/api/v1/goals/$id/contributions', body: body));
  Future<List<JsonMap>> contributions(int id) async =>
      _list(await client.get('/api/v1/goals/$id/contributions'));
  Future<JsonMap> deleteContribution(int goalId, int contributionId) async =>
      _map(
        await client.delete(
          '/api/v1/goals/$goalId/contributions/$contributionId',
        ),
      );

  Future<List<JsonMap>> alerts({
    bool unreadOnly = false,
    bool activeOnly = true,
    int limit = 50,
    int offset = 0,
  }) async => _list(
    await client.get(
      '/api/v1/budget-alerts/',
      query: {
        'unread_only': unreadOnly,
        'active_only': activeOnly,
        'limit': limit,
        'offset': offset,
      },
    ),
  );
  Future<JsonMap> unreadAlertCount() async =>
      _map(await client.get('/api/v1/budget-alerts/unread-count'));
  Future<JsonMap> readAllAlerts() async =>
      _map(await client.post('/api/v1/budget-alerts/read-all'));
  Future<JsonMap> readAlert(int id) async =>
      _map(await client.patch('/api/v1/budget-alerts/$id/read'));

  Future<JsonMap> createTransaction(JsonMap body) async =>
      _map(await client.post('/api/v1/transactions/', body: body));
  Future<List<JsonMap>> transactions({
    required int walletId,
    int limit = 50,
    int offset = 0,
  }) async => _list(
    await client.get(
      '/api/v1/transactions/',
      query: {'wallet_id': walletId, 'limit': limit, 'offset': offset},
    ),
  );
  Future<JsonMap> bulkTransactions(List<JsonMap> items) async => _map(
    await client.post(
      '/api/v1/transactions/bulk',
      body: {'transactions': items},
    ),
  );
  Future<JsonMap> transaction(int id) async =>
      _map(await client.get('/api/v1/transactions/$id'));
  Future<JsonMap> updateTransaction(int id, JsonMap body) async =>
      _map(await client.put('/api/v1/transactions/$id', body: body));
  Future<void> deleteTransaction(int id) async =>
      client.delete('/api/v1/transactions/$id');

  Future<List<JsonMap>> budgets() async =>
      _list(await client.get('/api/v1/budgets/'));
  Future<JsonMap> createBudget(JsonMap body) async =>
      _map(await client.post('/api/v1/budgets/', body: body));
  Future<List<JsonMap>> budgetStatuses({String? date}) async => _list(
    await client.get('/api/v1/budgets/status', query: {'on_date': date}),
  );
  Future<JsonMap> budget(int id) async =>
      _map(await client.get('/api/v1/budgets/$id'));
  Future<JsonMap> updateBudget(int id, JsonMap body) async =>
      _map(await client.put('/api/v1/budgets/$id', body: body));
  Future<void> deleteBudget(int id) async =>
      client.delete('/api/v1/budgets/$id');
  Future<JsonMap> budgetStatus(int id, {String? date}) async => _map(
    await client.get('/api/v1/budgets/$id/status', query: {'on_date': date}),
  );

  Future<JsonMap> monthlyReport(String month) async => _map(
    await client.get('/api/v1/reports/monthly', query: {'month': month}),
  );
  Future<JsonMap> categorySummary(String period) async => _map(
    await client.get(
      '/api/v1/reports/category-summary',
      query: {'period': period},
    ),
  );
  Future<Uint8List> monthlyReportPdf(String month) =>
      client.getBytes('/api/v1/reports/monthly.pdf', query: {'month': month});

  Future<List<JsonMap>> categorizationRules() async =>
      _list(await client.get('/api/v1/automation/rules'));
  Future<JsonMap> createCategorizationRule(JsonMap body) async =>
      _map(await client.post('/api/v1/automation/rules', body: body));
  Future<JsonMap> updateCategorizationRule(int id, JsonMap body) async =>
      _map(await client.put('/api/v1/automation/rules/$id', body: body));
  Future<void> deleteCategorizationRule(int id) async =>
      client.delete('/api/v1/automation/rules/$id');
  Future<JsonMap> testCategorizationRules(String description) async => _map(
    await client.post(
      '/api/v1/automation/rules/test-match',
      body: {'description': description},
    ),
  );
  Future<JsonMap> detectSubscriptions() async =>
      _map(await client.post('/api/v1/automation/subscriptions/detect'));
  Future<List<JsonMap>> subscriptions() async =>
      _list(await client.get('/api/v1/automation/subscriptions'));
  Future<JsonMap> updateSubscriptionStatus(int id, String status) async => _map(
    await client.patch(
      '/api/v1/automation/subscriptions/$id',
      body: {'status': status},
    ),
  );
  Future<JsonMap> syncBillingAlerts({int daysAhead = 7}) async => _map(
    await client.post(
      '/api/v1/automation/billing-alerts/sync',
      query: {'days_ahead': daysAhead},
    ),
  );
  Future<List<JsonMap>> billingAlerts() async =>
      _list(await client.get('/api/v1/automation/billing-alerts'));
  Future<JsonMap> readBillingAlert(int id) async =>
      _map(await client.patch('/api/v1/automation/billing-alerts/$id/read'));
}
