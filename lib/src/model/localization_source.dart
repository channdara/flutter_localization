enum LocalizationSource {
  /// Load translations from in-memory [MapLocale] definitions.
  map,

  /// Load translations from JSON asset files resolved via `rootBundle`.
  jsonAsset,
}
