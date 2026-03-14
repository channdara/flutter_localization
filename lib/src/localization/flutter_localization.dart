import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:universal_io/io.dart';

import '../../flutter_localization.dart';
import '../../flutter_localization_platform_interface.dart';
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
    _currentLocale = locale ?? await _platformLocale();
  }

  /// Get default locale object from string localeName of Platform class
  Future<Locale> _platformLocale() async {
    final localeName = kIsWeb
        ? await FlutterLocalizationPlatform.instance.getPlatformLocale()
        : Platform.localeName;
    final locale = localeName.split(RegExp(r'[-_]'));
    return Locale.fromSubtags(
      languageCode: locale.first,
      countryCode: locale.last,
      scriptCode: locale.length > 2 ? locale[1] : null,
    );
  }

  /// Initialize the localization configuration.
  ///
  /// When [source] is [LocalizationSource.map], provide [mapLocales] which
  /// contain in-memory string maps for each supported language.
  ///
  /// When [source] is [LocalizationSource.jsonAsset], provide [jsonLocales]
  /// which describe each supported locale and its JSON asset path.
  ///
  /// The [initLanguageCode] is usually loaded from shared preferences to
  /// determine the initial language when the app starts for the first time.
  void init({
    required String initLanguageCode,
    List<MapLocale>? mapLocales,
    LocalizationSource source = LocalizationSource.map,
    List<JsonLocale>? jsonLocales,
  }) {
    if (_currentLocale == null) throw const EnsureInitializeException();
    _supportedLocales = <Locale>[];
    _fontFamily.clear();
    switch (source) {
      case LocalizationSource.map:
        _configureFromMapLocales(mapLocales ?? <MapLocale>[]);
      case LocalizationSource.jsonAsset:
        _configureFromJsonLocales(jsonLocales ?? <JsonLocale>[]);
    }
    if (!_localeFromPreferences) {
      _currentLocale = _generateLocale(initLanguageCode);
    }
    // if (_currentLocale != null && source == LocalizationSource.jsonAsset) {
    //   await FlutterLocalizationTranslator.instance.load(_currentLocale!);
    // }
    _reload();
  }

  /// Configure localization using in-memory [MapLocale] definitions.
  ///
  /// This method populates the supported locales and optional font families
  /// based on the provided [locales], and forwards the configuration to
  /// [FlutterLocalizationTranslator] so it can resolve string values at
  /// runtime.
  void _configureFromMapLocales(List<MapLocale> locales) {
    FlutterLocalizationTranslator.instance.mapLocales = locales;
    _supportedLocales = locales.map((e) => e.locale).toList();
    for (final locale in locales) {
      _fontFamily.putIfAbsent(locale.languageCode, () => locale.fontFamily);
    }
  }

  /// Configure localization using JSON-backed [JsonLocale] definitions.
  ///
  /// Each [JsonLocale] describes a language code, optional region/script, an
  /// optional font family, and the asset path to the JSON file that contains
  /// the translations. This method validates the input, updates the supported
  /// locales and font families, and passes the configuration to
  /// [FlutterLocalizationTranslator].
  void _configureFromJsonLocales(List<JsonLocale> locales) {
    if (locales.isEmpty) {
      throw ArgumentError(
        'jsonLocales must be provided when using LocalizationSource.jsonAsset',
      );
    }
    FlutterLocalizationTranslator.instance.jsonLocales = locales;
    _supportedLocales = locales.map((e) => e.locale).toList();
    for (final locale in locales) {
      _fontFamily.putIfAbsent(locale.languageCode, () => locale.fontFamily);
    }
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
