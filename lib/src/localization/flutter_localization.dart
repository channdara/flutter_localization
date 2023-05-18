import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../model/map_locale.dart';
import '../utility/preference_util.dart';
import 'flutter_localization_delegate.dart';
import 'flutter_localization_translator.dart';

typedef TranslatorCallback = void Function(Locale?);

class FlutterLocalization {
  FlutterLocalization._singleton() {
    _delegate = FlutterLocalizationDelegate(null);
  }

  /// The instance object of [FlutterLocalization] class.
  static final FlutterLocalization instance = FlutterLocalization._singleton();

  /// The package delegate. This is private, only use in the package.
  late FlutterLocalizationDelegate _delegate;

  /// The list of supported language code provide by the [init] function
  List<String> _supportedLanguageCodes = const [];

  /// The current locale of the app. It will change after [translate] called.
  Locale? _currentLocale;

  /// Callback for the translation. This will call after the [translate]
  /// function is called.
  TranslatorCallback? onTranslatedLanguage;

  /// The map data that store all the provided font family from [MapLocale]
  final Map<String, String?> _fontFamily = {};

  /// Initialize the list of mapLocale (see [MapLocale] model for info)
  /// and initLanguageCode code when the app is start up. Both field will required.
  ///
  /// initLanguageCode mostly passed from the shared_preferences for checking
  /// the init language to display when the app is start up.
  Future<void> init({
    required List<MapLocale> mapLocales,
    required String initLanguageCode,
    String? initCountryCode,
  }) async {
    FlutterLocalizationTranslator.instance.mapLocales = mapLocales;
    _supportedLanguageCodes = mapLocales.map((e) => e.languageCode).toList();
    mapLocales.forEach((element) {
      _fontFamily.putIfAbsent(element.languageCode, () => element.fontFamily);
    });
    await _handleLocale(initLanguageCode, initCountryCode);
  }

  /// This will handle the locale of the app. Load the saved locale and init new
  /// delegate for the app localization.
  Future<void> _handleLocale(
    String initLanguageCode,
    String? initCountryCode,
  ) async {
    _currentLocale = Locale(initLanguageCode, initCountryCode);
    _currentLocale = await PreferenceUtil.getInitLocale(
      initLanguageCode,
      initCountryCode,
    );
    _delegate = FlutterLocalizationDelegate(_currentLocale);
    if (onTranslatedLanguage != null) onTranslatedLanguage!(_currentLocale);
  }

  /// Call this function at where you want to translate the app like by
  /// pressing the button or any actions.
  void translate(
    String languageCode, {
    String countryCode = '',
    bool save = true,
  }) {
    if (languageCode == _currentLocale?.languageCode) return;
    if (save) PreferenceUtil.setLocale(languageCode, countryCode);
    _currentLocale = Locale(languageCode, countryCode);
    _delegate = FlutterLocalizationDelegate(_currentLocale);
    if (onTranslatedLanguage != null) onTranslatedLanguage!(_currentLocale);
  }

  /// This just call the getName() function from [FlutterLocalizationTranslator]
  /// class for getting the full language name by the language code.
  String getLanguageName({String? languageCode}) =>
      FlutterLocalizationTranslator.instance
          .getName(languageCode ?? _currentLocale!.languageCode);

  /// Get the list of supported language code provide by the [init] function
  List<String> get supportedLanguageCodes => _supportedLanguageCodes;

  /// Get the current locale of the app.
  Locale? get currentLocale => _currentLocale;

  /// Generate the supported locales for the app.
  /// This will use at the MaterialAap
  Iterable<Locale> get supportedLocales =>
      _supportedLanguageCodes.map<Locale>((language) => Locale(language));

  /// Apply all the needed delegate and the package delegate for the app.
  /// This will use at the MaterialApp
  Iterable<LocalizationsDelegate<dynamic>> get localizationsDelegates => [
        _delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];

  /// Provide the font family by the current locale's language code
  String? get fontFamily => _fontFamily[_currentLocale?.languageCode];
}
