class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final Object? details;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}
