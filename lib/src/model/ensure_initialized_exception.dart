class EnsureInitializedException implements Exception {
  const EnsureInitializedException();

  @override
  String toString() =>
      'EnsureInitializedException: The ensureInitialized() is not called. Check README document for more information: https://pub.dev/packages/flutter_localization';
}
