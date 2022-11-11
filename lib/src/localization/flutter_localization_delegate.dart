import 'package:flutter/material.dart';

import '../../flutter_localization.dart';
import 'flutter_localization_translator.dart';

class FlutterLocalizationDelegate
    extends LocalizationsDelegate<FlutterLocalizationTranslator> {
  FlutterLocalizationDelegate(this.newLocale);

  final Locale? newLocale;

  /// The override function from [LocalizationsDelegate] to check the supported
  /// language provided by the app configuration
  @override
  bool isSupported(Locale locale) =>
      FlutterLocalization.instance.supportedLanguageCodes
          .contains(locale.languageCode);

  /// The override function from [LocalizationsDelegate] to load the locale
  @override
  Future<FlutterLocalizationTranslator> load(Locale locale) =>
      FlutterLocalizationTranslator.instance.load(newLocale ?? locale);

  /// The override function from [LocalizationsDelegate] to reload the locale.
  @override
  bool shouldReload(LocalizationsDelegate<FlutterLocalizationTranslator> old) =>
      true;
}
