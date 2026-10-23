import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin PreferenceUtil {
  static const String _locale_key = 'translator_locale_key';
  static const String _language_code = 'translator_language_code';
  static const String _country_code = 'translator_country_code';
  static const String _script_code = 'translator_script_code';

  /// Loads the saved locale.
  ///
  /// Returns null when nothing is stored. Malformed preference data is removed
  /// so the next launch can select a supported locale.
  static Future<Locale?> getLocale() async {
    final pref = await SharedPreferences.getInstance();
    final prefData = pref.getString(_locale_key);
    if (prefData == null) return null;
    final locale = _readLocale(prefData);
    if (locale != null) return locale;
    await pref.remove(_locale_key);
    return null;
  }

  /// Saves [locale], or removes the saved locale when [locale] is null.
  static Future<bool> setLocale(Locale? locale) async {
    final pref = await SharedPreferences.getInstance();
    if (locale == null) return pref.remove(_locale_key);
    final value = json.encode({
      _language_code: locale.languageCode,
      _country_code: locale.countryCode,
      _script_code: locale.scriptCode,
    });
    return pref.setString(_locale_key, value);
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

    final Object? language = decoded[_language_code];
    final Object? country = decoded[_country_code];
    final Object? script = decoded[_script_code];
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
