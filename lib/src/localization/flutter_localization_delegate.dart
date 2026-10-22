import 'package:flutter/material.dart';

import '../../flutter_localization.dart';
import 'flutter_localization_translator.dart';

/// Loads translations for the locale Flutter asks for.
///
/// [load] uses its [Locale] argument as-is. Pass
/// [FlutterLocalization.currentLocale] to `MaterialApp.locale` so this
/// delegate, Material, Cupertino, text direction, and `Localizations.localeOf`
/// all follow the same locale.
class FlutterLocalizationDelegate
    extends LocalizationsDelegate<FlutterLocalizationTranslator> {
  const FlutterLocalizationDelegate();

  /// The override function from [LocalizationsDelegate] to check the supported
  /// language provided by the app configuration
  @override
  bool isSupported(Locale locale) =>
      resolveSupportedLocale(
        locale,
        FlutterLocalization.instance.supportedLocales,
      ) !=
      null;

  /// The override function from [LocalizationsDelegate] to load the locale
  @override
  Future<FlutterLocalizationTranslator> load(Locale locale) =>
      FlutterLocalizationTranslator.instance.load(locale);

  /// Locale changes are applied through `MaterialApp.locale`. This delegate
  /// has no separate locale to compare.
  @override
  bool shouldReload(FlutterLocalizationDelegate old) => false;
}
