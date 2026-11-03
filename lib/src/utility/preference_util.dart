import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin PreferenceUtil {
  static const String _localeKey = 'translator_locale_key';
  static const String _languageCode = 'translator_language_code';
  static const String _countryCode = 'translator_country_code';
  static const String _scriptCode = 'translator_script_code';

  /// Loads the saved locale.
  ///
  /// Returns null when nothing is stored. Malformed preference data is removed
  /// so the next launch can select a supported locale.
  static Future<Locale?> getLocale() async {
    final pref = await SharedPreferences.getInstance();
    final prefData = pref.getString(_localeKey);
    if (prefData == null) return null;
    final locale = _readLocale(prefData);
    if (locale != null) return locale;
    await pref.remove(_localeKey);
    return null;
  }

  /// Saves [locale], or removes the saved locale when [locale] is null.
  static Future<bool> setLocale(Locale? locale) async {
    final pref = await SharedPreferences.getInstance();
    if (locale == null) return pref.remove(_localeKey);
    final value = json.encode({
      _languageCode: locale.languageCode,
      _countryCode: locale.countryCode,
      _scriptCode: locale.scriptCode,
    });
    return pref.setString(_localeKey, value);
  }

  /// Decodes the JSON preference [stored] into a [Locale].
  ///
  /// Returns null when the text is not a JSON object, the language code is
  /// missing or empty, a subtag has the wrong type, or the subtags cannot form
  /// a locale. [getLocale] treats that null as unreadable data and deletes the
  /// preference.
  static Locale? _readLocale(String stored) {
    final Object? decoded;
    try {
      decoded = jsonDecode(stored);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;

    final Object? language = decoded[_languageCode];
    final Object? country = decoded[_countryCode];
    final Object? script = decoded[_scriptCode];
    if (language is! String || language.isEmpty) return null;
    if (country is! String?) return null;
    if (script is! String?) return null;

    try {
      return Locale.fromSubtags(
        languageCode: language,
        countryCode: country,
        scriptCode: script,
      );
    } on ArgumentError {
      return null;
    } on AssertionError {
      return null;
    }
  }
}
