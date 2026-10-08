import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:spendlyapp/core/api/api_exception.dart';
import 'package:spendlyapp/core/api/expense_tracker_api.dart';
import 'package:spendlyapp/core/auth/token_store.dart';

enum SessionStatus { booting, unauthenticated, authenticated, unavailable }

class SessionController extends ChangeNotifier {
  SessionController({required this.api, required this.tokenStore});

  final ExpenseTrackerApi api;
  final TokenStore tokenStore;

  SessionStatus status = SessionStatus.booting;
  JsonMap? user;
  String? errorMessage;
  bool submitting = false;

  bool get isAuthenticated => status == SessionStatus.authenticated;

  Future<void> initialize() async {
    status = SessionStatus.booting;
    errorMessage = null;
    notifyListeners();
    try {
      await _wakeBackend();
      final token = await tokenStore.read();
      if (token == null || token.isEmpty) {
        status = SessionStatus.unauthenticated;
      } else {
        try {
          user = await api.getMe();
          status = SessionStatus.authenticated;
        } on ApiException catch (error) {
          if (!error.isUnauthorized) rethrow;
          await tokenStore.clear();
          status = SessionStatus.unauthenticated;
        }
      }
    } catch (_) {
      errorMessage = 'O servidor gratuito ainda não respondeu. Verifique sua conexão e tente novamente.';
      status = SessionStatus.unavailable;
    }
    notifyListeners();
  }

  Future<void> _wakeBackend() async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await api.health(timeout: const Duration(seconds: 30));
        return;
      } catch (error) {
        lastError = error;
        if (attempt < 2) await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
    throw lastError ?? StateError('Backend unavailable');
  }

  Future<void> login({required String email, required String password}) async {
    await _submit(() async {
      final response = await api.login(email.trim(), password);
      await tokenStore.write(response['access_token'] as String);
      user = await api.getMe();
      status = SessionStatus.authenticated;
    });
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _submit(() async {
      await api.register(
        email: email.trim(),
        password: password,
        fullName: name.trim(),
      );
      final response = await api.login(email.trim(), password);
      await tokenStore.write(response['access_token'] as String);
      user = await api.getMe();
      status = SessionStatus.authenticated;
    });
  }

  Future<void> startDemo() async {
    await _submit(() async {
      final response = await api.demoSession();
      await tokenStore.write(response['access_token'] as String);
      user = await api.getMe();
      status = SessionStatus.authenticated;
    });
  }

  Future<void> completeOnboarding() async {
    await _submit(() async {
      user = await api.updatePreferences({'onboarding_completed': true});
      status = SessionStatus.authenticated;
    });
  }

  Future<void> refreshUser() async {
    user = await api.getMe();
    notifyListeners();
  }

  Future<void> _submit(Future<void> Function() action) async {
    submitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } on ApiException catch (error) {
      errorMessage = error.message;
      rethrow;
    } catch (_) {
      errorMessage = 'Não foi possível conectar ao servidor.';
      rethrow;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await tokenStore.clear();
    user = null;
    errorMessage = null;
    status = SessionStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> handleUnauthorized() => logout();
}
