import 'package:flutter/material.dart';

class MapLocale {
  /// Constructor of the model.
  const MapLocale(
    this.languageCode,
    this.mapData, {
    this.countryCode,
    this.fontFamily,
    this.scriptCode,
  }) : assert(languageCode != '');

  /// Language code. This will use to check with the supported language codes
  /// and find the data for localization.
  final String languageCode;

  /// This is the map of data that will use for localization.
  final Map<String, dynamic> mapData;

  /// Country code is the region subtag for the locale.
  final String? countryCode;

  /// Font family for the language
  final String? fontFamily;

  /// The script subtag for the locale.
  final String? scriptCode;

  /// Create a Locale object from MapLocale object
  Locale get locale => Locale.fromSubtags(
        languageCode: languageCode,
        countryCode: countryCode,
        scriptCode: scriptCode,
      );
}
