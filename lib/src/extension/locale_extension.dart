import 'package:flutter/material.dart';

/// Parses a locale tag into a [Locale].
///
/// Accepts BCP 47 tags (`en`, `en-US`, `zh-Hant-TW`) and POSIX locale strings
/// (`en_US`, `en_US.UTF-8`, `en_US.UTF-8@euro`). Underscores are accepted for
/// compatibility with [localeIdentifier]. A codeset (`.UTF-8`) or modifier
/// (`@euro`) is removed before the subtags are read.
///
/// Subtags are recognized by length, not by position. The language is never
/// copied into the country, so `en` stays language-only. A script is four
/// letters and a region is two letters or three digits, in either order.
///
/// Throws [FormatException] when [localeTag] is empty or a subtag is not a
/// language, script, or region.
Locale parseLocale(String localeTag) {
  final normalized = _withoutEncodingOrModifier(localeTag.trim());
  final subtags = normalized.split(RegExp(r'[-_]'));
  if (normalized.isEmpty || subtags.first.isEmpty) {
    throw FormatException('Invalid locale tag: $localeTag');
  }

  final languageCode = subtags.first;
  if (!_isLanguageSubtag(languageCode)) {
    throw FormatException(
      'Unsupported locale subtag "$languageCode": $localeTag',
    );
  }

  String? scriptCode;
  String? countryCode;
  for (final subtag in subtags.skip(1)) {
    if (scriptCode == null && _isScriptSubtag(subtag)) {
      scriptCode = _titleCaseScript(subtag);
    } else if (countryCode == null && _isRegionSubtag(subtag)) {
      countryCode = subtag.toUpperCase();
    } else {
      throw FormatException('Unsupported locale subtag "$subtag": $localeTag');
    }
  }

  return Locale.fromSubtags(
    languageCode: languageCode.toLowerCase(),
    scriptCode: scriptCode,
    countryCode: countryCode,
  );
}

/// Removes a POSIX codeset and modifier from [localeTag].
///
/// `en_US.UTF-8@euro` becomes `en_US`. The modifier starts at `@` and the
/// codeset starts at `.`. Text after either marker is not a locale subtag.
String _withoutEncodingOrModifier(String localeTag) {
  final modifierIndex = localeTag.indexOf('@');
  final withoutModifier =
      modifierIndex >= 0 ? localeTag.substring(0, modifierIndex) : localeTag;
  final encodingIndex = withoutModifier.indexOf('.');
  if (encodingIndex < 0) return withoutModifier;
  return withoutModifier.substring(0, encodingIndex);
}

/// Reports whether [subtag] is a primary language subtag.
///
/// A language is two or three letters, or five to eight letters. Four letters
/// is a script. `POSIX` is a charset locale name, not a language.
bool _isLanguageSubtag(String subtag) {
  if (subtag.toLowerCase() == 'posix') return false;
  if (!RegExp(r'^[A-Za-z]+$').hasMatch(subtag)) return false;
  final length = subtag.length;
  return length == 2 || length == 3 || length >= 5 && length <= 8;
}

/// Reports whether [subtag] is a four-letter script subtag.
bool _isScriptSubtag(String subtag) =>
    subtag.length == 4 && RegExp(r'^[A-Za-z]+$').hasMatch(subtag);

/// Reports whether [subtag] is a region: two letters or three digits.
bool _isRegionSubtag(String subtag) =>
    (subtag.length == 2 && RegExp(r'^[A-Za-z]+$').hasMatch(subtag)) ||
    (subtag.length == 3 && RegExp(r'^[0-9]+$').hasMatch(subtag));

/// Returns [script] in title case, such as `hant` to `Hant`.
String _titleCaseScript(String script) =>
    '${script[0].toUpperCase()}${script.substring(1).toLowerCase()}';

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
