import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/language_name.dart';
import '../model/json_locale.dart';
import '../model/localization_source.dart';
import '../model/map_locale.dart';

class FlutterLocalizationTranslator {
  /// Private instance constructor.
  FlutterLocalizationTranslator._instance();

  /// The instance object of [FlutterLocalizationTranslator] class.
  static final FlutterLocalizationTranslator instance =
      FlutterLocalizationTranslator._instance();

  Map<String, dynamic> _string = {};
  List<MapLocale> _mapLocales = [];
  LocalizationSource _source = LocalizationSource.map;
  List<JsonLocale> _jsonLocales = [];

  static FlutterLocalizationTranslator? of(BuildContext context) =>
      Localizations.of<FlutterLocalizationTranslator>(
          context, FlutterLocalizationTranslator);

  void mapLocales(List<MapLocale> mapLocales) {
    _mapLocales = mapLocales;
    _source = LocalizationSource.map;
  }

  void jsonLocales(List<JsonLocale> jsonLocales) {
    _jsonLocales = jsonLocales;
    _source = LocalizationSource.jsonAsset;
  }

  /// This function will load the value from either the provided [MapLocale]
  /// data or from JSON asset files (depending on [LocalizationSource]) and
  /// return an instance of the [FlutterLocalizationTranslator] class.
  Future<FlutterLocalizationTranslator> load(Locale locale) async {
    switch (_source) {
      case LocalizationSource.map:
        _string = _mapLocales
            .where((e) => e.languageCode == locale.languageCode)
            .first
            .mapData;
      case LocalizationSource.jsonAsset:
        JsonLocale jsonLocale;
        try {
          jsonLocale = _jsonLocales
              .firstWhere((e) => e.languageCode == locale.languageCode);
        } catch (_) {
          _string = {};
          break;
        }
        final jsonString = await rootBundle.loadString(jsonLocale.assetPath);
        final dynamic decoded = jsonDecode(jsonString);
        if (decoded is Map<String, dynamic>) {
          _string = decoded;
        } else if (decoded is Map) {
          _string =
              decoded.map((key, value) => MapEntry(key.toString(), value));
        } else {
          _string = {};
        }
    }
    return instance;
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
