import 'package:flutter/material.dart';

/// A locale whose translations are loaded from a JSON asset.
///
/// The file at [assetPath] must be a flat JSON object of string values.
/// Nested objects, arrays, numbers, booleans, and null fail the load with
/// [FormatException].
class JsonLocale {
  /// Constructor of the model.
  const JsonLocale(
    this.languageCode,
    this.assetPath, {
    this.countryCode,
    this.fontFamily,
    this.scriptCode,
  })  : assert(languageCode != ''),
        assert(assetPath != '');

  /// Language code. This will use to check with the supported language codes
  /// and find the data for localization.
  final String languageCode;

  /// Path to the JSON asset that contains the translations for this locale.
  final String assetPath;

  /// Country code is the region subtag for the locale.
  final String? countryCode;

  /// Font family for the language.
  final String? fontFamily;

  /// The script subtag for the locale.
  final String? scriptCode;

  /// Create a Locale object from JsonLocale object.
  Locale get locale => Locale.fromSubtags(
        languageCode: languageCode,
        countryCode: countryCode,
        scriptCode: scriptCode,
      );
}
