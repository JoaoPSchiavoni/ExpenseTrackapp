class ApiConfig {
  const ApiConfig._();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://expense-tracker-api-jivv.onrender.com',
  );

  static const requestTimeout = Duration(seconds: 30);
  static const wakeUpTimeout = Duration(seconds: 90);
}
