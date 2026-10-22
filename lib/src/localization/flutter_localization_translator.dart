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
      (String jsonString) => _decodeStrings(jsonString),
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

  static Map<String, dynamic> _decodeStrings(String jsonString) {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is Map<String, dynamic>) return _copyMap(decoded);
    if (decoded is Map) {
      final copy = <String, dynamic>{};
      for (final MapEntry<dynamic, dynamic> entry in decoded.entries) {
        copy[entry.key.toString()] = entry.value;
      }
      return copy.isEmpty
          ? const <String, dynamic>{}
          : Map<String, dynamic>.unmodifiable(copy);
    }
    return const <String, dynamic>{};
  }

  static Map<String, dynamic> _copyMap(Map<String, dynamic> source) {
    if (source.isEmpty) return const <String, dynamic>{};
    return Map<String, dynamic>.unmodifiable(
      Map<String, dynamic>.of(source),
    );
  }

  /// This function will return the value of the map data which loaded by the
  /// [load] function above.
  String getString(String key) =>
      _string[key] == null ? '$key not found' : _string[key].toString();

  /// This function is the same as [getString] above. But instead of returning
  /// 'key not found', this will return onl the key
  String getStringOrKey(String key) =>
      _string[key] == null ? key : _string[key].toString();

  /// This function will return the language name by the language code provided.
  String getName(String languageCode) => languageName[languageCode] == null
      ? 'Name for $languageCode not found'
      : languageName[languageCode].toString();
}
