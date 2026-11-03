import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const traditionalChinese = Locale.fromSubtags(
    languageCode: 'zh',
    scriptCode: 'Hant',
    countryCode: 'TW',
  );

  test('language-only tag does not copy the language into the country', () {
    final locale = parseLocale('en');

    expect(locale, const Locale('en'));
    expect(locale.countryCode, isNull);
    expect(locale.scriptCode, isNull);
  });

  test('language and region tags keep both subtags', () {
    expect(parseLocale('en-US'), const Locale('en', 'US'));
    expect(parseLocale('en_US'), const Locale('en', 'US'));
    expect(parseLocale('EN-us'), const Locale('en', 'US'));
  });

  test('script and region tags keep each subtag', () {
    expect(parseLocale('zh-Hant-TW'), traditionalChinese);
    expect(parseLocale('zh_Hant_TW'), traditionalChinese);
    expect(parseLocale('zh-hant-tw'), traditionalChinese);
    expect(parseLocale('zh-TW-Hant'), traditionalChinese);
  });

  test('posix encoding and modifier suffixes are removed', () {
    expect(parseLocale('en_US.UTF-8'), const Locale('en', 'US'));
    expect(parseLocale('en_US.UTF-8@euro'), const Locale('en', 'US'));
    expect(parseLocale('en.UTF-8'), const Locale('en'));
    expect(
        parseLocale(' zh-Hant-TW.UTF-8@collation=pinyin '), traditionalChinese);
  });

  test('numeric regions stay regions', () {
    expect(parseLocale('es-419'), const Locale('es', '419'));
  });

  test('malformed locale tags are rejected', () {
    const malformed = <String>[
      '',
      '   ',
      '-',
      'en-',
      'en--US',
      'C',
      'POSIX',
      'en-US-extra',
      'en-US-GB',
      'en-Latn-Hant',
      '123',
      '.UTF-8',
      '@euro',
    ];

    for (final tag in malformed) {
      expect(() => parseLocale(tag), throwsFormatException, reason: tag);
    }
  });
}
