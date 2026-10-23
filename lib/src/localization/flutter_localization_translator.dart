import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/language_name.dart';
import '../extension/locale_extension.dart';
import '../model/json_locale.dart';
import '../model/load_request.dart';
import '../model/localization_source.dart';
import '../model/map_locale.dart';

typedef _AssetLoader = Future<String> Function(String assetPath);

/// Immutable strings for one loaded locale.
///
/// [FlutterLocalizationTranslator.instance] only stores configuration. [load]
/// returns a new instance so a finished asset read cannot change strings that
/// are already on screen.
class FlutterLocalizationTranslator {
  FlutterLocalizationTranslator._(this._string);

  /// The instance object of [FlutterLocalizationTranslator] class.
  static final FlutterLocalizationTranslator instance =
      FlutterLocalizationTranslator._(const <String, dynamic>{});

  static _AssetLoader _assetLoader = rootBundle.loadString;
  static int _generation = 0;
  static LocalizationSource _source = LocalizationSource.map;
  static List<MapLocale> _mapLocales = <MapLocale>[];
  static List<JsonLocale> _jsonLocales = <JsonLocale>[];
  static final Map<String, Map<String, dynamic>> _jsonCache =
      <String, Map<String, dynamic>>{};
  static final Map<String, Future<Map<String, dynamic>>> _jsonInFlight =
      <String, Future<Map<String, dynamic>>>{};
  static final List<LoadRequest> _pending = <LoadRequest>[];

  final Map<String, dynamic> _string;

  /// Changes when [mapLocales] or [jsonLocales] replaces the sources.
  static int get configurationId => _generation;

  /// Replaces JSON asset loading. Pass null to restore [rootBundle].
  @visibleForTesting
  static void debugSetAssetLoader(
    Future<String> Function(String assetPath)? loader,
  ) {
    _assetLoader = loader ?? rootBundle.loadString;
  }

  /// Clears cached JSON and any in-flight load bookkeeping.
  @visibleForTesting
  static void debugReset() {
    _assetLoader = rootBundle.loadString;
    _generation++;
    _source = LocalizationSource.map;
    _mapLocales = <MapLocale>[];
    _jsonLocales = <JsonLocale>[];
    _jsonCache.clear();
    _jsonInFlight.clear();
    final leftover = List<LoadRequest>.of(_pending);
    _pending.clear();
    final empty = FlutterLocalizationTranslator._(const <String, dynamic>{});
    for (final request in leftover) {
      request.settle(empty);
    }
  }

  static FlutterLocalizationTranslator? of(BuildContext context) =>
      Localizations.of<FlutterLocalizationTranslator>(
        context,
        FlutterLocalizationTranslator,
      );

  void mapLocales(List<MapLocale> mapLocales) {
    _replaceSource(LocalizationSource.map);
    _mapLocales = mapLocales;
  }

  void jsonLocales(List<JsonLocale> jsonLocales) {
    _replaceSource(LocalizationSource.jsonAsset);
    _jsonLocales = jsonLocales;
  }

  /// Starts reading every configured JSON asset into the cache.
  ///
  /// [preferred] is requested first so the locale on screen is ahead of the
  /// other files. Map sources are already in memory, so this returns without
  /// reading. Each JSON asset is decoded once. [load] reuses the cached map or
  /// the in-flight read, and reports a decode failure.
  void preload(Locale? preferred) {
    if (_source != LocalizationSource.jsonAsset) return;
    final generation = _generation;
    for (final JsonLocale jsonLocale in _jsonLocalesPreferredFirst(preferred)) {
      _loadJsonAsset(jsonLocale, generation).ignore();
    }
  }

  /// Puts the JSON locale that matches [preferred] ahead of the others.
  ///
  /// The remaining locales keep their configured order. When [preferred] is
  /// null, unmatched, or already first, the stored list is returned.
  static List<JsonLocale> _jsonLocalesPreferredFirst(Locale? preferred) {
    if (preferred == null || _jsonLocales.length < 2) return _jsonLocales;
    final resolved = resolveSupportedLocale(
      preferred,
      _jsonLocales.map((JsonLocale entry) => entry.locale),
    );
    if (resolved == null) return _jsonLocales;
    final index = _jsonLocales.indexWhere(
      (JsonLocale entry) => entry.locale == resolved,
    );
    if (index <= 0) return _jsonLocales;
    return <JsonLocale>[
      _jsonLocales[index],
      ..._jsonLocales.sublist(0, index),
      ..._jsonLocales.sublist(index + 1),
    ];
  }

  static void _replaceSource(LocalizationSource source) {
    _generation++;
    _source = source;
    _jsonCache.clear();
    _jsonInFlight.clear();
  }

  /// Loads strings for [locale].
  ///
  /// Overlapping calls resolve to the newest request. Flutter applies whichever
  /// delegate future finishes last, so an older call must not complete again
  /// after a newer locale has been published.
  Future<FlutterLocalizationTranslator> load(Locale locale) {
    final generation = _generation;
    final ready = _stringsIfReady(locale);
    if (ready != null && _pending.isEmpty) {
      return SynchronousFuture<FlutterLocalizationTranslator>(
        FlutterLocalizationTranslator._(ready),
      );
    }

    final request = LoadRequest();
    _pending.add(request);
    if (ready != null) {
      request.strings = ready;
      _publishPending();
      return request.future;
    }

    _readJson(locale, generation).then<void>(
      (Map<String, dynamic> strings) {
        if (request.settled) return;
        request.strings = strings;
        _publishPending();
      },
      onError: (Object error, StackTrace stackTrace) {
        if (request.settled) return;
        request.fail(error, stackTrace);
        _publishPending();
      },
    );
    return request.future;
  }

  /// Publishes the newest ready request and completes older requests with that
  /// same snapshot, oldest first.
  static void _publishPending() {
    if (_pending.isEmpty || !_pending.last.isReady) return;

    final latest = _pending.last;
    final requests = List<LoadRequest>.of(_pending);
    _pending.clear();

    final error = latest.error;
    if (error != null) {
      final stackTrace = latest.stackTrace ?? StackTrace.empty;
      for (final request in requests) {
        request.settleError(error, stackTrace);
      }
      return;
    }

    final snapshot = FlutterLocalizationTranslator._(latest.strings!);
    for (final request in requests) {
      request.settle(snapshot);
    }
  }

  static Map<String, dynamic>? _stringsIfReady(Locale locale) {
    switch (_source) {
      case LocalizationSource.map:
        return _stringsFromMaps(locale);
      case LocalizationSource.jsonAsset:
        return _cachedJson(locale);
    }
  }

  static Map<String, dynamic> _stringsFromMaps(Locale locale) {
    final resolved = resolveSupportedLocale(
      locale,
      _mapLocales.map((MapLocale entry) => entry.locale),
    );
    if (resolved == null) return const <String, dynamic>{};
    final data = _mapLocales
        .firstWhere((MapLocale entry) => entry.locale == resolved)
        .mapData;
    return _copyMap(data);
  }

  static Map<String, dynamic>? _cachedJson(Locale locale) {
    final resolved = resolveSupportedLocale(
      locale,
      _jsonLocales.map((JsonLocale entry) => entry.locale),
    );
    if (resolved == null) return const <String, dynamic>{};
    return _jsonCache[resolved.localeIdentifier];
  }

  static Future<Map<String, dynamic>> _readJson(
    Locale locale,
    int generation,
  ) {
    final resolved = resolveSupportedLocale(
      locale,
      _jsonLocales.map((JsonLocale entry) => entry.locale),
    );
    if (resolved == null) {
      return SynchronousFuture<Map<String, dynamic>>(
        const <String, dynamic>{},
      );
    }
    final jsonLocale = _jsonLocales.firstWhere(
      (JsonLocale entry) => entry.locale == resolved,
    );
    return _loadJsonAsset(jsonLocale, generation);
  }

  static Future<Map<String, dynamic>> _loadJsonAsset(
    JsonLocale jsonLocale,
    int generation,
  ) {
    final cacheKey = jsonLocale.locale.localeIdentifier;
    final cached = _jsonCache[cacheKey];
    if (cached != null) {
      return SynchronousFuture<Map<String, dynamic>>(cached);
    }

    final inFlight = _jsonInFlight[cacheKey];
    if (inFlight != null) return inFlight;

    late final Future<Map<String, dynamic>> future;
    future = _assetLoader(jsonLocale.assetPath)
        .then<Map<String, dynamic>>(
      (String jsonString) => _decodeStrings(
        jsonString,
        assetPath: jsonLocale.assetPath,
      ),
    )
        .then<Map<String, dynamic>>((Map<String, dynamic> strings) {
      if (generation == _generation &&
          identical(_jsonInFlight[cacheKey], future)) {
        _jsonCache[cacheKey] = strings;
      }
      return strings;
    }).whenComplete(() {
      if (identical(_jsonInFlight[cacheKey], future)) {
        _jsonInFlight.remove(cacheKey);
      }
    });
    _jsonInFlight[cacheKey] = future;
    return future;
  }

  /// Decodes [jsonString] into a flat map of translation strings.
  ///
  /// The root must be a JSON object, and every value must be a string. Nested
  /// objects, arrays, numbers, booleans, and null are rejected.
  ///
  /// Throws [FormatException] when the text is not valid JSON, or when the
  /// document is not a flat object of strings. [assetPath] is included in
  /// that message when it is provided.
  static Map<String, dynamic> _decodeStrings(
    String jsonString, {
    String? assetPath,
  }) {
    final dynamic decoded = jsonDecode(jsonString);
    final where = assetPath == null
        ? 'Translation JSON'
        : 'Translation file "$assetPath"';
    if (decoded is! Map) {
      throw FormatException(
        '$where must be a JSON object of string values. Found ${_describeJsonValue(decoded)}.',
      );
    }

    final copy = <String, dynamic>{};
    for (final MapEntry<dynamic, dynamic> entry in decoded.entries) {
      final Object? key = entry.key;
      final Object? value = entry.value;
      if (key is! String) {
        throw FormatException(
          '$where keys must be strings. Found ${_describeJsonValue(key)}.',
        );
      }
      if (value is! String) {
        throw FormatException(
          '$where values must be strings. Key "$key" is ${_describeJsonValue(value)}.',
        );
      }
      copy[key] = value;
    }
    return copy.isEmpty
        ? const <String, dynamic>{}
        : Map<String, dynamic>.unmodifiable(copy);
  }

  /// Returns a short label for [value] used in JSON format errors.
  static String _describeJsonValue(Object? value) {
    if (value == null) return 'null';
    if (value is Map) return 'a nested object';
    if (value is List) return 'an array';
    if (value is num) return 'a number';
    if (value is bool) return 'a boolean';
    if (value is String) return 'a string';
    return 'type ${value.runtimeType}';
  }

  static Map<String, dynamic> _copyMap(Map<String, dynamic> source) {
    if (source.isEmpty) return const <String, dynamic>{};
    return Map<String, dynamic>.unmodifiable(
      Map<String, dynamic>.of(source),
    );
  }

  /// Returns the translation stored for [key].
  ///
  /// A missing key returns `key not found`.
  String getString(String key) =>
      _string[key] == null ? '$key not found' : _string[key].toString();

  /// Returns the translation stored for [key], or [key] when it is missing.
  ///
  /// Callers that format text use this so an unresolved key stays available
  /// for `%a` replacement.
  String getStringOrKey(String key) =>
      _string[key] == null ? key : _string[key].toString();

  /// This function will return the language name by the language code provided.
  String getName(String languageCode) => languageName[languageCode] == null
      ? 'Name for $languageCode not found'
      : languageName[languageCode].toString();
}
