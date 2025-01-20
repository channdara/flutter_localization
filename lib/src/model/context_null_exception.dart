class ContextNullException implements Exception {
  const ContextNullException();

  @override
  String toString() =>
      'ContextNullException: Current context is null, make sure you have set the navigatorKey at MaterialApp with localization.navigatorKey';
}
