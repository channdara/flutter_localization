import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';

import '../../flutter_localization.dart';
import '../delegate/cupertino_localizations.dart';
import '../delegate/material_localizations.dart';
import '../delegate/widgets_localizations.dart';
import '../model/ensure_initialized_exception.dart';
import '../utility/preference_util.dart';
import 'flutter_localization_delegate.dart';
import 'flutter_localization_translator.dart';

typedef TranslatorCallback = void Function(Locale?);

class FlutterLocalization {
  /// Private instance constructor.
  FlutterLocalization._instance();

  /// The instance object of [FlutterLocalization] class.
  static final FlutterLocalization instance = FlutterLocalization._instance();

  /// The package delegate. This is private, only use in the package.
  FlutterLocalizationDelegate _delegate = FlutterLocalizationDelegate(null);

  /// The list of supported locale provide by the [init] function
  List<Locale> _supportedLocales = [];

  /// The current locale of the app. It will change after [translate] called.
  Locale? _currentLocale;

  /// The boolean indicate that locale is load from shared preferences.
  bool _localeFromPreferences = false;

  /// Callback for the translation. This will call after the [translate]
  /// function is called.
  TranslatorCallback? onTranslatedLanguage;

  /// The map data that store all the provided font family from [MapLocale]
  final Map<String, String?> _fontFamily = {};

  /// To ensure the currentLocale object is provided before runApp
  Future<void> ensureInitialized() async {
    final locale = await PreferenceUtil.getLocale();
    _localeFromPreferences = locale != null;
    _currentLocale = locale ?? _platformLocale();
  }

  /// Get default locale object from string localeName of Platform class
  Locale _platformLocale() {
    final locale = Platform.localeName.split(RegExp(r'[-_]'));
    return Locale.fromSubtags(
      languageCode: locale.first,
      countryCode: locale.last,
      scriptCode: locale.length > 2 ? locale[1] : null,
    );
  }

  /// Initialize the list of mapLocale (see [MapLocale] model for info)
  /// and initLanguageCode code when the app is start up. Both field will required.
  ///
  /// initLanguageCode mostly passed from the shared_preferences for checking
  /// the init language to display when the app is start up.
  void init({
    required List<MapLocale> mapLocales,
    required String initLanguageCode,
  }) {
    if (_currentLocale == null) throw const EnsureInitializeException();
    FlutterLocalizationTranslator.instance.mapLocales = mapLocales;
    _supportedLocales = mapLocales.map((e) => e.locale).toList();
    mapLocales.forEach((e) {
      _fontFamily.putIfAbsent(e.languageCode, () => e.fontFamily);
    });
    if (!_localeFromPreferences) {
      _currentLocale = _generateLocale(initLanguageCode);
    }
    _reload();
  }

  /// This will generate new locale base on provided languageCode. The locale
  /// data is getting from [_supportedLocales] list.
  Locale _generateLocale(String languageCode) {
    final countryCode = _getCountryCode(languageCode);
    final scriptCode = _getScriptCode(languageCode);
    return Locale.fromSubtags(
      languageCode: languageCode,
      countryCode: countryCode,
      scriptCode: scriptCode,
    );
  }

  /// Call this function at where you want to translate the app like by
  /// pressing the button or any actions.
  void translate(
    String languageCode, {
    bool save = true,
  }) {
    if (languageCode == _currentLocale?.languageCode) return;
    _currentLocale = _generateLocale(languageCode);
    if (save) PreferenceUtil.setLocale(_currentLocale);
    _reload();
  }

  /// Reload the delegate with new locale and call the callback for app reload.
  void _reload() {
    _delegate = FlutterLocalizationDelegate(_currentLocale);
    onTranslatedLanguage?.call(_currentLocale);
  }

  /// Get country code from the list of MapLocale provided by the [init] function
  /// that base on language code
  String? _getCountryCode(String languageCode) {
    return _supportedLocales
        .singleWhere((element) => element.languageCode == languageCode)
        .countryCode;
  }

  /// Get script code from the list of MapLocale provided by the [init] function
  /// that base on language code
  String? _getScriptCode(String languageCode) {
    return _supportedLocales
        .singleWhere((element) => element.languageCode == languageCode)
        .scriptCode;
  }

  /// This just call the getName() function from [FlutterLocalizationTranslator]
  /// class for getting the full language name by the language code.
  String getLanguageName({String? languageCode}) =>
      FlutterLocalizationTranslator.instance
          .getName(languageCode ?? _currentLocale!.languageCode);

  /// Get the list of supported language code provided by the [init] function
  List<String> get supportedLanguageCodes =>
      _supportedLocales.map((e) => e.languageCode).toList();

  /// Get the current locale of the app.
  Locale? get currentLocale => _currentLocale;

  /// Generate the supported locales for the app.
  /// This will use at the MaterialAap
  Iterable<Locale> get supportedLocales => _supportedLocales;

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
