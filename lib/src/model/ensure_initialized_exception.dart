class EnsureInitializeException implements Exception {
  const EnsureInitializeException();

  @override
  String toString() =>
      'EnsureInitializeException: The ensureInitialized() is not called. Check README document for more information: https://pub.dev/packages/flutter_localization';
}
