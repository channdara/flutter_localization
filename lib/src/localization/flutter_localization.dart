import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../flutter_localization.dart';
import '../data/language_name.dart';
import '../utility/preference_util.dart';
import 'flutter_localization_delegate.dart';
import 'flutter_localization_translator.dart';

/// Legacy callback invoked with the locale selected by [FlutterLocalization].
///
/// Prefer [FlutterLocalization.addListener] and
/// [FlutterLocalization.removeListener], or a [ListenableBuilder]. Those
/// support more than one subscriber.
typedef TranslatorCallback = void Function(Locale? locale);

/// Coordinates the selected locale and the translations Flutter loads.
///
/// This object is a [ChangeNotifier]. Listen to [FlutterLocalization.instance]
/// with [FlutterLocalization.addListener] and
/// [FlutterLocalization.removeListener], or with a [ListenableBuilder], and
/// pass [currentLocale] to `MaterialApp.locale` so package strings and
/// Flutter's own locale stay aligned. Remove a listener when its owner is
/// disposed. The shared instance is not meant to be disposed.
class FlutterLocalization extends ChangeNotifier {
  /// Private instance constructor.
  FlutterLocalization._instance();

  /// The instance object of [FlutterLocalization] class.
  static final FlutterLocalization instance = FlutterLocalization._instance();

  /// The list of supported locale provide by the [init] function
  List<Locale> _supportedLocales = [];

  /// The current locale of the app. It will change after [translate] called.
  Locale? _currentLocale;

  /// Locale stored in preferences, when the stored value could be read.
  ///
  /// [init] resolves this against the supported locales. A value that resolves
  /// to a different supported locale is rewritten. A value that does not
  /// resolve is removed.
  Locale? _persistedLocale;

  /// Single callback invoked after [init] or [translate] changes the locale.
  ///
  /// Listen with [addListener] and [removeListener], or with a
  /// [ListenableBuilder], so more than one owner can subscribe and each can
  /// unregister when it is disposed. Assigning this replaces the previous
  /// callback. It does not remove listeners registered with [addListener].
  /// Rebuild with `locale: currentLocale`.
  @Deprecated(
    'Listen with addListener and removeListener, or with ListenableBuilder. '
    'Assigning onTranslatedLanguage replaces the previous callback.',
  )
  TranslatorCallback? onTranslatedLanguage;

  /// Font families keyed by full locale identity.
  final Map<String, String?> _fontFamily = {};

  static final List<LocalizationsDelegate<dynamic>> _flutterDelegates =
      List<LocalizationsDelegate<dynamic>>.unmodifiable(
    <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
  );

  /// Loads the saved locale so [currentLocale] is available before runApp.
  ///
  /// When nothing is saved, or the stored value cannot be read, [currentLocale]
  /// is the platform locale until [init] runs. An unreadable preference is
  /// removed.
  Future<void> ensureInitialized() async {
    _persistedLocale = await PreferenceUtil.getLocale();
    _currentLocale =
        _persistedLocale ?? WidgetsBinding.instance.platformDispatcher.locale;
  }

  /// Initializes supported locales and selects the locale to display.
  ///
  /// When [source] is [LocalizationSource.map], provide [mapLocales] which
  /// contain in-memory string maps for each supported language.
  ///
  /// When [source] is [LocalizationSource.jsonAsset], provide [jsonLocales]
  /// which describe each supported locale and its JSON asset path.
  ///
  /// [initLanguageCode] is the configured startup language, such as `en` or
  /// `zh-Hant`. It is not loaded from preferences. The displayed locale is
  /// chosen in this order:
  ///
  /// 1. The saved locale, when it resolves to one supported locale. A saved
  ///    value that resolves to a different supported locale is rewritten. A
  ///    saved value that does not resolve is removed.
  /// 2. [initLanguageCode], when it names one supported locale.
  /// 3. The platform locale, when it resolves to one supported locale.
  /// 4. The first locale in [mapLocales] or [jsonLocales].
  ///
  /// JSON assets begin loading before listeners are notified. The selected
  /// locale is requested first, then the other configured locales. Later loads
  /// reuse those decoded maps.
  ///
  /// Throws [ArgumentError] when the locale list is empty, when the same
  /// language, script, and country is configured twice, or when
  /// [initLanguageCode] cannot be parsed or matches more than one variant.
  void init({
    required String initLanguageCode,
    LocalizationSource source = LocalizationSource.map,
    List<MapLocale>? mapLocales,
    List<JsonLocale>? jsonLocales,
  }) {
    if (_currentLocale == null) throw const EnsureInitializedException();
    switch (source) {
      case LocalizationSource.map:
        _configureFromMapLocales(mapLocales ?? <MapLocale>[]);
      case LocalizationSource.jsonAsset:
        _configureFromJsonLocales(jsonLocales ?? <JsonLocale>[]);
    }
    _currentLocale = _selectStartupLocale(initLanguageCode);
    FlutterLocalizationTranslator.instance.preload(_currentLocale);
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
    final resolvedLocales = locales.map((e) => e.locale).toList();
    _rejectDuplicateLocales(resolvedLocales, 'mapLocales');
    FlutterLocalizationTranslator.instance.mapLocales(locales);
    _supportedLocales = resolvedLocales;
    _fontFamily
      ..clear()
      ..addAll(<String, String?>{
        for (final locale in locales)
          locale.locale.localeIdentifier: locale.fontFamily,
      });
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
    final resolvedLocales = locales.map((e) => e.locale).toList();
    _rejectDuplicateLocales(resolvedLocales, 'jsonLocales');
    FlutterLocalizationTranslator.instance.jsonLocales(locales);
    _supportedLocales = resolvedLocales;
    _fontFamily
      ..clear()
      ..addAll(<String, String?>{
        for (final locale in locales)
          locale.locale.localeIdentifier: locale.fontFamily,
      });
  }

  /// Chooses the locale [init] should display.
  ///
  /// Resolution order is the saved locale, then [initLanguageCode], then the
  /// platform locale, then the first configured locale. A saved locale that
  /// resolves to a different supported locale is rewritten. One that does not
  /// resolve is removed. An [initLanguageCode] that matches more than one
  /// variant throws [ArgumentError].
  Locale _selectStartupLocale(String initLanguageCode) {
    final requestedInit = _parseInitLanguage(initLanguageCode);
    final initResolved = resolveSupportedLocale(
      requestedInit,
      _supportedLocales,
    );
    final initMatches = _localesWithLanguage(requestedInit);
    if (initResolved == null && initMatches.length > 1) {
      throw ArgumentError.value(
        initLanguageCode,
        'initLanguageCode',
        'Startup locale "$initLanguageCode" matches more than one supported locale (${_describeLocales(initMatches)}). Use a full locale tag such as "en-US" or "zh-Hant".',
      );
    }

    if (_persistedLocale != null) {
      final resolved = resolveSupportedLocale(
        _persistedLocale!,
        _supportedLocales,
      );
      if (resolved != null) {
        if (resolved != _persistedLocale) {
          _storeLocale(resolved);
        }
        return resolved;
      }
      _storeLocale(null);
    }

    if (initResolved != null) return initResolved;
    final platformResolved = resolveSupportedLocale(
      WidgetsBinding.instance.platformDispatcher.locale,
      _supportedLocales,
    );
    if (platformResolved != null) return platformResolved;
    return _supportedLocales.first;
  }

  /// Parses [initLanguageCode] into a [Locale].
  ///
  /// Tags that [parseLocale] rejects are rethrown as an [ArgumentError] named
  /// `initLanguageCode`, so startup configuration fails with the parameter
  /// that the caller passed.
  Locale _parseInitLanguage(String initLanguageCode) {
    try {
      return parseLocale(initLanguageCode);
    } catch (error) {
      throw ArgumentError.value(
        initLanguageCode,
        'initLanguageCode',
        error.toString(),
      );
    }
  }

  /// Keeps [locale] as the saved locale in memory and in preferences.
  ///
  /// Pass null to forget the saved locale. The preference write is started
  /// and not awaited.
  void _storeLocale(Locale? locale) {
    _persistedLocale = locale;
    PreferenceUtil.setLocale(locale);
  }

  /// Throws [ArgumentError] when [locales] lists the same locale twice.
  ///
  /// Comparison uses [_localeIdentity], so letter case does not make two
  /// entries distinct. [parameterName] is included in the error so the message
  /// points at `mapLocales` or `jsonLocales`.
  void _rejectDuplicateLocales(List<Locale> locales, String parameterName) {
    final seen = <String>{};
    for (final locale in locales) {
      final identity = _localeIdentity(locale);
      if (!seen.add(identity)) {
        throw ArgumentError.value(
          identity,
          parameterName,
          'Duplicate locale "$identity". Each language, script, and country combination must be configured once.',
        );
      }
    }
  }

  /// Returns supported locales that share [requested]'s language code.
  ///
  /// The language comparison is case-insensitive. Script and country are
  /// ignored, so this is used to detect an ambiguous language-only request.
  List<Locale> _localesWithLanguage(Locale requested) {
    final language = requested.languageCode.toLowerCase();
    return _supportedLocales
        .where((Locale locale) => locale.languageCode.toLowerCase() == language)
        .toList(growable: false);
  }

  /// Joins [locales] as a comma-separated list of locale identifiers.
  ///
  /// Used in [ArgumentError] messages so the caller can see which configured
  /// locales were considered.
  String _describeLocales(Iterable<Locale> locales) =>
      locales.map((Locale locale) => locale.localeIdentifier).join(', ');

  /// Builds a `language_script_country` key for comparing [locale] values.
  ///
  /// Language is lowercase, script is title case, and country is uppercase.
  /// Missing script or country parts are left out, so `en` and `en_US` stay
  /// different while `en_us` and `en_US` share one key.
  String _localeIdentity(Locale locale) {
    return <String>[
      locale.languageCode.toLowerCase(),
      _normalizedScript(locale.scriptCode) ?? '',
      _normalizedCountry(locale.countryCode) ?? '',
    ].where((String part) => part.isNotEmpty).join('_');
  }

  /// Returns [script] in title case, such as `hant` to `Hant`.
  ///
  /// Returns null when [script] is null or empty.
  String? _normalizedScript(String? script) {
    if (script == null || script.isEmpty) return null;
    return '${script[0].toUpperCase()}${script.substring(1).toLowerCase()}';
  }

  /// Returns [country] in upper case, such as `us` to `US`.
  ///
  /// Returns null when [country] is null or empty.
  String? _normalizedCountry(String? country) {
    if (country == null || country.isEmpty) return null;
    return country.toUpperCase();
  }

  /// Returns the single supported locale that matches [requested].
  ///
  /// Delegates the match to [resolveSupportedLocale]. Throws [ArgumentError]
  /// when no configured locale matches, or when [requested] names a language
  /// that has more than one configured variant.
  Locale _resolveLocale(Locale requested) {
    final locale = resolveSupportedLocale(requested, _supportedLocales);
    if (locale != null) return locale;

    final matches = _localesWithLanguage(requested);
    if (matches.length > 1) {
      throw ArgumentError.value(
        requested.localeIdentifier,
        'locale',
        'Locale "${requested.localeIdentifier}" matches more than one supported locale (${_describeLocales(matches)}). Use a full locale tag such as "en-US" or "zh-Hant".',
      );
    }
    throw ArgumentError.value(
      requested.localeIdentifier,
      'locale',
      'Locale "${requested.localeIdentifier}" is not supported. Configured locales: ${_describeLocales(_supportedLocales)}.',
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
  ///
  /// When translations come from JSON, that asset is requested before
  /// listeners rebuild if it is not already cached or in flight.
  void translateLocale(
    Locale locale, {
    bool save = true,
  }) {
    final resolved = _resolveLocale(locale);
    if (resolved == _currentLocale) return;
    _currentLocale = resolved;
    if (save) _storeLocale(resolved);
    FlutterLocalizationTranslator.instance.preload(resolved);
    _reload();
  }

  /// Notifies listeners that [currentLocale] changed so the app can rebuild
  /// `MaterialApp` with that locale.
  ///
  /// The legacy [onTranslatedLanguage] callback runs first. Listeners
  /// registered with [addListener] are still notified when that callback
  /// throws.
  void _reload() {
    try {
      onTranslatedLanguage?.call(_currentLocale);
    } finally {
      notifyListeners();
    }
  }

  /// Returns the language's own name for [languageCode].
  ///
  /// When [languageCode] is omitted, the current locale's language code is
  /// used. The result is the name speakers of that language use for it, such
  /// as `English` or `日本語`. It is not translated into the current UI locale,
  /// and script or country variants share that language-code name. An unknown
  /// code returns `Name for <code> not found`.
  String getLanguageName({String? languageCode}) =>
      languageNameFor(languageCode ?? _currentLocale!.languageCode);

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
  /// This will use at the MaterialApp.
  ///
  /// The package delegate carries the current source configuration, so replacing
  /// map or JSON data reloads strings on the next build.
  Iterable<LocalizationsDelegate<dynamic>> get localizationsDelegates =>
      List<LocalizationsDelegate<dynamic>>.unmodifiable(
        <LocalizationsDelegate<dynamic>>[
          FlutterLocalizationDelegate(
            FlutterLocalizationTranslator.configurationId,
          ),
          ..._flutterDelegates,
        ],
      );

  /// Provides the font family configured for the current locale.
  String? get fontFamily => _fontFamily[_currentLocale.localeIdentifier];
}
