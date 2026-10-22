import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../flutter_localization.dart';
import '../model/ensure_initialized_exception.dart';
import '../utility/preference_util.dart';
import 'flutter_localization_delegate.dart';
import 'flutter_localization_translator.dart';

typedef TranslatorCallback = void Function(Locale?);

/// Coordinates the selected locale and the translations Flutter loads.
///
/// This object is a [ChangeNotifier]. Listen to [FlutterLocalization.instance]
/// and pass [currentLocale] to `MaterialApp.locale` (usually from a
/// [ListenableBuilder]) so package strings and Flutter's own locale stay
/// aligned. The shared instance is not meant to be disposed.
class FlutterLocalization extends ChangeNotifier {
  /// Private instance constructor.
  FlutterLocalization._instance();

  /// The instance object of [FlutterLocalization] class.
  static final FlutterLocalization instance = FlutterLocalization._instance();

  /// The list of supported locale provide by the [init] function
  List<Locale> _supportedLocales = [];

  /// The current locale of the app. It will change after [translate] called.
  Locale? _currentLocale;

  /// The boolean indicate that locale is load from shared preferences.
  bool _localeFromPreferences = false;

  /// Callback for the translation. This will call after the [translate]
  /// function is called.
  ///
  /// Prefer listening to this [ChangeNotifier] instead. A later assignment
  /// replaces the previous callback. Either way, rebuild with
  /// `locale: currentLocale`.
  TranslatorCallback? onTranslatedLanguage;

  /// Font families keyed by full locale identity.
  final Map<String, String?> _fontFamily = {};

  static final List<LocalizationsDelegate<dynamic>> _localizationsDelegates =
      List<LocalizationsDelegate<dynamic>>.unmodifiable(
    <LocalizationsDelegate<dynamic>>[
      const FlutterLocalizationDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
  );

  /// To ensure the currentLocale object is provided before runApp
  Future<void> ensureInitialized() async {
    final locale = await PreferenceUtil.getLocale();
    _localeFromPreferences = locale != null;
    _currentLocale =
        locale ?? WidgetsBinding.instance.platformDispatcher.locale;
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
    LocalizationSource source = LocalizationSource.map,
    List<MapLocale>? mapLocales,
    List<JsonLocale>? jsonLocales,
  }) {
    if (_currentLocale == null) throw const EnsureInitializeException();
    _supportedLocales.clear();
    _fontFamily.clear();
    switch (source) {
      case LocalizationSource.map:
        _configureFromMapLocales(mapLocales ?? <MapLocale>[]);
      case LocalizationSource.jsonAsset:
        _configureFromJsonLocales(jsonLocales ?? <JsonLocale>[]);
    }
    if (!_localeFromPreferences) {
      _currentLocale = _resolveLocale(parseLocale(initLanguageCode));
    }
    _reload();
  }

  /// Configure localization using in-memory [MapLocale] definitions.
  ///
  /// This method populates the supported locales and optional font families
  /// based on the provided [locales], and forwards the configuration to
  /// [FlutterLocalizationTranslator] so it can resolve string values at
  /// runtime.
  void _configureFromMapLocales(List<MapLocale> locales) {
    if (locales.isEmpty) {
      throw ArgumentError(
        'mapLocales must be provided when using LocalizationSource.map',
      );
    }
    FlutterLocalizationTranslator.instance.mapLocales(locales);
    _supportedLocales = locales.map((e) => e.locale).toList();
    for (final locale in locales) {
      _fontFamily[locale.locale.localeIdentifier] = locale.fontFamily;
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
    FlutterLocalizationTranslator.instance.jsonLocales(locales);
    _supportedLocales = locales.map((e) => e.locale).toList();
    for (final locale in locales) {
      _fontFamily[locale.locale.localeIdentifier] = locale.fontFamily;
    }
  }

  Locale _resolveLocale(Locale requested) {
    final locale = resolveSupportedLocale(requested, _supportedLocales);
    if (locale != null) return locale;

    throw ArgumentError.value(
      requested.localeIdentifier,
      'locale',
      'Locale is unsupported or ambiguous. Use a full locale tag when multiple variants of a language are configured.',
    );
  }

  /// Call this function at where you want to translate the app like by
  /// pressing the button or any actions. [localeTag] may be a language code
  /// (`en`) or a full locale tag (`en-US` or `zh-Hant`).
  void translate(
    String localeTag, {
    bool save = true,
  }) {
    translateLocale(parseLocale(localeTag), save: save);
  }

  /// Changes the app to the supported locale matching [locale].
  void translateLocale(
    Locale locale, {
    bool save = true,
  }) {
    final resolved = _resolveLocale(locale);
    if (resolved == _currentLocale) return;
    _currentLocale = resolved;
    if (save) PreferenceUtil.setLocale(_currentLocale);
    _reload();
  }

  /// Notifies listeners that [currentLocale] changed so the app can rebuild
  /// `MaterialApp` with that locale.
  void _reload() {
    onTranslatedLanguage?.call(_currentLocale);
    notifyListeners();
  }

  /// This just call the getName() function from [FlutterLocalizationTranslator]
  /// class for getting the full language name by the language code.
  String getLanguageName({String? languageCode}) =>
      FlutterLocalizationTranslator.instance
          .getName(languageCode ?? _currentLocale!.languageCode);

  /// Get the list of supported language code provided by the [init] function
  List<String> get supportedLanguageCodes =>
      _supportedLocales.map((e) => e.languageCode).toList();

  /// Full identifiers for the locales provided by [init].
  List<String> get supportedLocaleIdentifiers =>
      _supportedLocales.map((e) => e.localeIdentifier).toList();

  /// The locale the app should display.
  ///
  /// Pass this to `MaterialApp.locale`. It changes when [init] or [translate]
  /// runs, and listeners are notified so the app can rebuild.
  Locale? get currentLocale => _currentLocale;

  /// Generate the supported locales for the app.
  /// This will use at the MaterialAap
  Iterable<Locale> get supportedLocales => _supportedLocales;

  /// Apply all the needed delegate and the package delegate for the app.
  /// This will use at the MaterialApp
  Iterable<LocalizationsDelegate<dynamic>> get localizationsDelegates =>
      _localizationsDelegates;

  /// Provides the font family configured for the current locale.
  String? get fontFamily => _fontFamily[_currentLocale.localeIdentifier];
}
