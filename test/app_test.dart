import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spendlyapp/app.dart';
import 'package:spendlyapp/core/api/api_client.dart';
import 'package:spendlyapp/core/api/expense_tracker_api.dart';
import 'package:spendlyapp/core/auth/session_controller.dart';
import 'package:spendlyapp/core/auth/token_store.dart';
import 'package:spendlyapp/core/theme/theme_controller.dart';
import 'package:spendlyapp/features/budgets/presentation/budgets_page.dart';
import 'package:spendlyapp/features/resources/presentation/resources_page.dart';
import 'package:spendlyapp/features/statistics/presentation/statistics_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a camada de API cobre as 80 operações sem duplicatas', () {
    final operations = ExpenseTrackerApi.supportedOperations;
    expect(operations, hasLength(80));
    expect(operations.map((item) => item.key).toSet(), hasLength(80));
  });

  testWidgets('exibe o dashboard real e alterna entre os temas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ThemeController.forTest();
    await tester.pumpWidget(
      SpendlyApp(themeController: controller, session: _session()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Olá, João 👋'), findsOneWidget);
    expect(find.text('Patrimônio total'), findsOneWidget);
    expect(find.text('Gastos por categoria'), findsNothing);
    expect(find.text('Inteligência financeira'), findsOneWidget);
    expect(find.text('Mês em déficit'), findsOneWidget);
    expect(find.text('1 orçamento em risco'), findsOneWidget);
    expect(controller.isDark, isFalse);
    await tester.tap(find.byKey(const ValueKey('theme-toggle')));
    await tester.pumpAndSettle();
    expect(controller.isDark, isTrue);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('cash-flow-donut-button')),
      300,
    );
    await tester.tap(find.byKey(const ValueKey('cash-flow-donut-button')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byKey(const ValueKey('interactive-cash-flow-donut')),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 8));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('cash-flow-bars')), findsOneWidget);
  });

  testWidgets('abre e salva uma transação pela API', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      SpendlyApp(
        themeController: ThemeController.forTest(isDark: true),
        session: _session(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-transaction')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('transaction-amount')),
      '125,90',
    );
    await tester.tap(find.byKey(const ValueKey('save-transaction')));
    await tester.pumpAndSettle();
    expect(find.text('Nova transação'), findsNothing);
    expect(find.text('Despesa salva com sucesso.'), findsOneWidget);
  });

  testWidgets('usa navegação lateral em uma tela desktop', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      SpendlyApp(
        themeController: ThemeController.forTest(isDark: true),
        session: _session(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Spendly'), findsOneWidget);
    expect(find.text('Nova transação'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('o gráfico anual explica e seleciona cada mês', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = MemoryTokenStore('token');
    final client = MockClient((request) async {
      dynamic body;
      if (request.url.path.endsWith('/reports/monthly')) {
        body = {
          'month': '2026-10',
          'currency': 'BRL',
          'total_income': '0.00',
          'total_expense': '4481.00',
          'net_savings': '-4481.00',
        };
      } else if (request.url.path.endsWith('/reports/category-summary')) {
        body = {'period': '2026-10', 'currency': 'BRL', 'items': []};
      } else {
        body = {
          'currency': 'BRL',
          'items': [
            {
              'month': '2026-09',
              'income': '8500.00',
              'expense': '4484.00',
              'net': '4016.00',
            },
            {
              'month': '2026-10',
              'income': '0.00',
              'expense': '4481.00',
              'net': '-4481.00',
            },
          ],
        };
      }
      return http.Response(
        jsonEncode(body),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = ExpenseTrackerApi(
      ApiClient(
        baseUrl: 'https://example.test',
        accessToken: store.read,
        httpClient: client,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StatisticsPage(
          api: api,
          themeController: ThemeController.forTest(isDark: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Receitas x despesas'), findsOneWidget);
    expect(
      find.text('Últimos 12 meses · toque em um mês para ver os valores'),
      findsOneWidget,
    );
    expect(find.text('Outubro de 2026'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('annual-flow-selected-summary')),
      findsOneWidget,
    );

    final september = find.byKey(const ValueKey('annual-flow-month-2026-09'));
    await tester.ensureVisible(september);
    await tester.tap(september);
    await tester.pumpAndSettle();
    expect(find.text('Setembro de 2026'), findsOneWidget);
  });

  testWidgets('exibe o novo login e alterna para criação de conta', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      SpendlyApp(
        themeController: ThemeController.forTest(),
        session: _unauthenticatedSession(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo de volta!'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-email')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-password')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('auth-mode-toggle')));
    await tester.pumpAndSettle();

    expect(find.text('Crie sua conta'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-name')), findsOneWidget);
  });

  testWidgets('cria orçamento geral sem exigir categoria', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Map<String, dynamic>? submittedBody;
    final store = MemoryTokenStore('token');
    final client = MockClient((request) async {
      final path = request.url.path;
      if (request.method == 'POST' && path.endsWith('/budgets/')) {
        submittedBody = Map<String, dynamic>.from(
          jsonDecode(request.body) as Map,
        );
        return http.Response(
          jsonEncode({
            'id': 1,
            'user_id': 1,
            'category_id': null,
            'limit_amount': '500.00',
            'period': 'MONTHLY',
            'alert_threshold': 80,
            'alerts_enabled': true,
            'created_at': '2026-10-07T12:00:00Z',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        '[]',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = ExpenseTrackerApi(
      ApiClient(
        baseUrl: 'https://example.test',
        accessToken: store.read,
        httpClient: client,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BudgetsPage(
            themeController: ThemeController.forTest(),
            api: api,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Novo orçamento'));
    await tester.pumpAndSettle();

    expect(find.text('Todas as categorias'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '500');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(submittedBody, isNotNull);
    expect(submittedBody, isNot(contains('category_id')));
    expect(submittedBody!['limit_amount'], '500');
    expect(find.text('Orçamento salvo.'), findsOneWidget);
  });

  testWidgets('cadastra uma transação recorrente', (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Map<String, dynamic>? submittedBody;
    final store = MemoryTokenStore('token');
    final client = MockClient((request) async {
      final path = request.url.path;
      dynamic body;
      var status = 200;
      if (request.method == 'POST' &&
          path.endsWith('/recurring-transactions/')) {
        submittedBody = Map<String, dynamic>.from(
          jsonDecode(request.body) as Map,
        );
        status = 201;
        body = {
          'id': 1,
          'user_id': 1,
          'wallet_id': 1,
          'category_id': null,
          'amount': submittedBody!['amount'],
          'transaction_type': submittedBody!['transaction_type'],
          'description': submittedBody!['description'],
          'frequency': submittedBody!['frequency'],
          'interval_count': submittedBody!['interval_count'],
          'start_date': submittedBody!['start_date'],
          'next_run_date': submittedBody!['start_date'],
          'end_date': null,
          'is_active': true,
          'last_generated_at': null,
          'created_at': '2026-10-07T12:00:00Z',
          'updated_at': '2026-10-07T12:00:00Z',
        };
      } else if (path.endsWith('/wallets/')) {
        body = [
          {'id': 1, 'name': 'Principal', 'currency': 'BRL', 'balance': '1000'},
        ];
      } else {
        body = [];
      }
      return http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = ExpenseTrackerApi(
      ApiClient(
        baseUrl: 'https://example.test',
        accessToken: store.read,
        httpClient: client,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResourcesPage(
            api: api,
            themeController: ThemeController.forTest(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('add-recurring-transaction')).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('recurring-amount')),
      '79,90',
    );
    await tester.tap(find.byKey(const ValueKey('save-recurring-transaction')));
    await tester.pumpAndSettle();

    expect(submittedBody, isNotNull);
    expect(submittedBody!['wallet_id'], 1);
    expect(submittedBody!['amount'], '79.90');
    expect(submittedBody!['transaction_type'], 'EXPENSE');
    expect(submittedBody!['frequency'], 'MONTHLY');
    expect(find.text('Recorrência salva.'), findsOneWidget);
  });
}

SessionController _unauthenticatedSession() {
  final store = MemoryTokenStore();
  final client = MockClient(
    (_) async =>
        http.Response('{}', 200, headers: {'content-type': 'application/json'}),
  );
  final session = SessionController(
    api: ExpenseTrackerApi(
      ApiClient(
        baseUrl: 'https://example.test',
        accessToken: store.read,
        httpClient: client,
      ),
    ),
    tokenStore: store,
  );
  session.status = SessionStatus.unauthenticated;
  return session;
}

SessionController _session() {
  final store = MemoryTokenStore('token');
  final client = MockClient((request) async {
    final path = request.url.path;
    dynamic body;
    if (path.endsWith('/dashboard/overview')) {
      body = {
        'month': '2026-10',
        'currency': 'BRL',
        'total_income': '1000',
        'total_expense': '250',
        'net_savings': '750',
        'savings_rate': '75',
        'transaction_count': 2,
        'net_worth': '5000',
        'active_wallets': 1,
        'active_goals': 0,
        'completed_goals': 0,
        'budgets_warning': 0,
        'budgets_exceeded': 0,
        'unread_alerts': 0,
        'generated_at': '2026-10-04T00:00:00Z',
      };
    } else if (path.endsWith('/dashboard/cash-flow')) {
      body = {
        'currency': 'BRL',
        'items': [
          {
            'month': '2026-10',
            'income': '1000',
            'expense': '250',
            'net': '750',
          },
        ],
      };
    } else if (path.endsWith('/dashboard/spending-by-category')) {
      body = {
        'month': '2026-10',
        'currency': 'BRL',
        'items': [
          {
            'category_id': 1,
            'category_name': 'Alimentação',
            'amount': '150',
            'percentage': '60',
          },
          {
            'category_id': 2,
            'category_name': 'Transporte',
            'amount': '100',
            'percentage': '40',
          },
        ],
      };
    } else if (path.endsWith('/dashboard/balance-projection')) {
      body = {
        'currency': 'BRL',
        'current_balance': '5000.00',
        'items': [
          {
            'month': '2026-10',
            'projected_income': '1000.00',
            'projected_expense': '250.00',
            'net_change': '750.00',
            'projected_balance': '5750.00',
          },
          {
            'month': '2026-11',
            'projected_income': '1000.00',
            'projected_expense': '250.00',
            'net_change': '750.00',
            'projected_balance': '6500.00',
          },
        ],
      };
    } else if (path.endsWith('/dashboard/period-comparison')) {
      body = {
        'current_period': '2026-10',
        'previous_period': '2026-09',
        'current_income': '1000.00',
        'previous_income': '800.00',
        'income_change_percentage': '25.00',
        'current_expense': '250.00',
        'previous_expense': '300.00',
        'expense_change_percentage': '-16.67',
        'current_net': '750.00',
        'previous_net': '500.00',
        'net_change': '250.00',
      };
    } else if (path.endsWith('/dashboard/financial-health')) {
      body = {
        'score': 7,
        'status': 'CRITICAL',
        'summary': 'Priorize o controle de gastos e a criação de reserva.',
        'savings_rate': '-19900.00',
        'reserve_months': '0.00',
        'budgets_on_track': 0,
        'budgets_at_risk': 1,
        'active_goals': 1,
      };
    } else if (path.endsWith('/dashboard/recommendations')) {
      body = [
        {
          'priority': 'LOW',
          'category': 'MAINTENANCE',
          'title': 'Continue assim',
          'message': 'Seus principais indicadores estão equilibrados.',
        },
      ];
    } else if (path.endsWith('/dashboard/recent-transactions')) {
      body = [];
    } else if (path.endsWith('/wallets/')) {
      body = [
        {'id': 1, 'name': 'Principal', 'currency': 'BRL', 'balance': '5000'},
      ];
    } else if (path.endsWith('/categories/')) {
      body = [
        {'id': 1, 'name': 'Alimentação'},
      ];
    } else if (path.endsWith('/transactions/')) {
      body = request.method == 'POST'
          ? {
              'transaction': {'id': 1},
              'updated_wallet_balance': '4874.10',
            }
          : [];
    } else if (path.endsWith('/recurring-transactions/process-due')) {
      body = {
        'generated': 0,
        'transaction_ids': [],
        'processed_through': '2026-10-07',
      };
    } else if (path.endsWith('/recurring-transactions/')) {
      body = [];
    } else {
      body = {};
    }
    return http.Response(
      jsonEncode(body),
      request.method == 'POST' ? 201 : 200,
      headers: {'content-type': 'application/json'},
    );
  });
  final session = SessionController(
    api: ExpenseTrackerApi(
      ApiClient(
        baseUrl: 'https://example.test',
        accessToken: store.read,
        httpClient: client,
      ),
    ),
    tokenStore: store,
  );
  session.status = SessionStatus.authenticated;
  session.user = {
    'id': 1,
    'full_name': 'João Teste',
    'email': 'joao@example.com',
    'base_currency': 'BRL',
    'timezone': 'America/Sao_Paulo',
  };
  return session;
}
