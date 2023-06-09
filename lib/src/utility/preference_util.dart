import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin PreferenceUtil {
  static const String _locale_key = 'translator_locale_key';
  static const String _language_code = 'translator_language_code';
  static const String _country_code = 'translator_country_code';

  /// Load the saved locale in the shared_preferences.
  static Future<Locale?> _getLocale() async {
    final pref = await SharedPreferences.getInstance();
    final prefData = pref.getString(_locale_key);
    if (prefData == null) return null;
    final locale = jsonDecode(prefData) as Map<String, dynamic>;
    return Locale(
      locale[_language_code].toString(),
      locale[_country_code].toString(),
    );
  }

  /// Save the locale value to the shared_preferences.
  static Future<bool> setLocale(
    String languageCode,
    String? countryCode,
  ) async {
    final pref = await SharedPreferences.getInstance();
    final value = json.encode({
      _language_code: languageCode,
      _country_code: countryCode,
    });
    return pref.setString(_locale_key, value);
  }

  /// Generate the current locale which will use for displaying the language
  /// which the app is change during translate() function called.
  static Future<Locale?> getInitLocale(String? lInit, String? cInit) async {
    return await _getLocale() ?? Locale(lInit ?? 'en', cInit ?? '');
  }
}
