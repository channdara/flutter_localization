import 'package:flutter/material.dart';

/// Parses a BCP-47-style locale tag such as `en-US` or `zh-Hans-CN`.
///
/// Underscores are accepted for compatibility with [localeIdentifier].
Locale parseLocale(String localeTag) {
  final subtags = localeTag.split(RegExp('[-_]'));
  if (subtags.isEmpty || subtags.first.isEmpty) {
    throw FormatException('Invalid locale tag: $localeTag');
  }

  String? scriptCode;
  String? countryCode;
  for (final subtag in subtags.skip(1)) {
    if (scriptCode == null &&
        subtag.length == 4 &&
        RegExp(r'^[A-Za-z]+$').hasMatch(subtag)) {
      scriptCode =
          '${subtag[0].toUpperCase()}${subtag.substring(1).toLowerCase()}';
    } else if (countryCode == null &&
        ((subtag.length == 2 && RegExp(r'^[A-Za-z]+$').hasMatch(subtag)) ||
            (subtag.length == 3 && RegExp(r'^[0-9]+$').hasMatch(subtag)))) {
      countryCode = subtag.toUpperCase();
    } else {
      throw FormatException('Unsupported locale subtag "$subtag": $localeTag');
    }
  }

  return Locale.fromSubtags(
    languageCode: subtags.first.toLowerCase(),
    scriptCode: scriptCode,
    countryCode: countryCode,
  );
}

/// Resolves [requested] against [supported] without discarding locale subtags.
///
/// Resolution tries an exact match, then a locale with the region omitted,
/// then the base language. As a compatibility fallback, a language-only
/// request resolves when exactly one supported locale has that language.
Locale? resolveSupportedLocale(
  Locale requested,
  Iterable<Locale> supported,
) {
  final locales = supported.toList(growable: false);

  Locale? uniqueWhere(bool Function(Locale locale) predicate) {
    final matches = locales.where(predicate).toList(growable: false);
    return matches.length == 1 ? matches.single : null;
  }

  bool sameLanguage(Locale locale) =>
      locale.languageCode.toLowerCase() == requested.languageCode.toLowerCase();
  bool sameScript(Locale locale) => locale.scriptCode == requested.scriptCode;
  bool sameCountry(Locale locale) =>
      locale.countryCode == requested.countryCode;

  final exact = uniqueWhere(
    (locale) =>
        sameLanguage(locale) && sameScript(locale) && sameCountry(locale),
  );
  if (exact != null) return exact;

  if (requested.countryCode != null) {
    final withoutCountry = uniqueWhere(
      (locale) =>
          sameLanguage(locale) &&
          sameScript(locale) &&
          locale.countryCode == null,
    );
    if (withoutCountry != null) return withoutCountry;
  }

  final baseLanguage = uniqueWhere(
    (locale) =>
        sameLanguage(locale) &&
        locale.scriptCode == null &&
        locale.countryCode == null,
  );
  if (baseLanguage != null) return baseLanguage;

  return uniqueWhere(sameLanguage);
}

extension LocaleExtension on Locale? {
  String get localeIdentifier {
    return [
      this?.languageCode ?? '',
      this?.scriptCode ?? '',
      this?.countryCode ?? '',
    ].where((element) => element.isNotEmpty).join('_');
  }
}
