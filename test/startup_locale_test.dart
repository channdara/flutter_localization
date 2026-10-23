import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_localization/src/localization/flutter_localization_translator.dart';
import 'package:flutter_localization/src/utility/preference_util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _preferenceKey = 'translator_locale_key';

const _english = MapLocale('en', <String, dynamic>{'title': 'Hello'});
const _japanese = MapLocale('ja', <String, dynamic>{'title': 'こんにちは'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterLocalizationTranslator.debugReset();
  });

  tearDown(FlutterLocalizationTranslator.debugReset);

  test('saved locale is used when it is supported', () async {
    await PreferenceUtil.setLocale(const Locale('ja'));
    final localization = await _load();

    localization.init(
      initLanguageCode: 'en',
      mapLocales: const <MapLocale>[_english, _japanese],
    );

    expect(localization.currentLocale, const Locale('ja'));
    await _expectSaved(const Locale('ja'));
  });

  test('supported saved locale is kept when startup language is unknown',
      () async {
    await PreferenceUtil.setLocale(const Locale('ja'));
    final localization = await _load();

    localization.init(
      initLanguageCode: 'zz',
      mapLocales: const <MapLocale>[_english, _japanese],
    );

    expect(localization.currentLocale, const Locale('ja'));
    await _expectSaved(const Locale('ja'));
  });

  test('unsupported saved locale is removed and startup language is used',
      () async {
    await PreferenceUtil.setLocale(const Locale('fr'));
    final localization = await _load();

    localization.init(
      initLanguageCode: 'en',
      mapLocales: const <MapLocale>[_english, _japanese],
    );

    expect(localization.currentLocale, const Locale('en'));
    await _expectSaved(null);
  });

  test('saved locale is rewritten when it resolves to another supported locale',
      () async {
    await PreferenceUtil.setLocale(const Locale('en'));
    final localization = await _load();

    localization.init(
      initLanguageCode: 'ja',
      mapLocales: const <MapLocale>[
        MapLocale(
          'en',
          <String, dynamic>{'title': 'Color'},
          countryCode: 'US',
        ),
      ],
    );

    expect(localization.currentLocale, const Locale('en', 'US'));
    await _expectSaved(const Locale('en', 'US'));
  });

  test('region-only saved locale is rewritten to the base language', () async {
    await PreferenceUtil.setLocale(const Locale('en', 'US'));
    final localization = await _load();

    localization.init(
      initLanguageCode: 'ja',
      mapLocales: const <MapLocale>[_english, _japanese],
    );

    expect(localization.currentLocale, const Locale('en'));
    await _expectSaved(const Locale('en'));
  });

  test('ambiguous saved locale is removed and the startup tag is used',
      () async {
    await PreferenceUtil.setLocale(const Locale('en'));
    final localization = await _load();

    localization.init(
      initLanguageCode: 'en-GB',
      mapLocales: const <MapLocale>[
        MapLocale(
          'en',
          <String, dynamic>{'title': 'Color'},
          countryCode: 'US',
        ),
        MapLocale(
          'en',
          <String, dynamic>{'title': 'Colour'},
          countryCode: 'GB',
        ),
      ],
    );

    expect(localization.currentLocale, const Locale('en', 'GB'));
    await _expectSaved(null);
  });

  test('unsupported startup language uses the platform locale', () async {
    final localization = await _load();
    final platform = WidgetsBinding.instance.platformDispatcher.locale;
    final other =
        _unusedLanguage(<String>[platform.languageCode.toLowerCase()]);

    localization.init(
      initLanguageCode: 'zz',
      mapLocales: <MapLocale>[
        MapLocale(other, const <String, dynamic>{'title': 'Other'}),
        MapLocale(
          platform.languageCode,
          const <String, dynamic>{'title': 'Platform'},
        ),
      ],
    );

    expect(
      localization.currentLocale,
      resolveSupportedLocale(platform, localization.supportedLocales),
    );
    expect(
      localization.currentLocale?.languageCode.toLowerCase(),
      isNot(other),
    );
  });

  test('unsupported saved and startup locales fall back to the first locale',
      () async {
    await PreferenceUtil.setLocale(const Locale('fr'));
    final localization = await _load();
    final platformLanguage = WidgetsBinding
        .instance.platformDispatcher.locale.languageCode
        .toLowerCase();
    final first = _unusedLanguage(<String>[platformLanguage]);
    final second = _unusedLanguage(<String>[platformLanguage, first]);

    localization.init(
      initLanguageCode: 'zz',
      mapLocales: <MapLocale>[
        MapLocale(first, const <String, dynamic>{'title': 'First'}),
        MapLocale(second, const <String, dynamic>{'title': 'Second'}),
      ],
    );

    expect(localization.currentLocale?.languageCode, first);
    await _expectSaved(null);
  });

  test('ambiguous startup language is rejected', () async {
    await PreferenceUtil.setLocale(const Locale('en', 'GB'));
    final localization = await _load();

    expect(
      () => localization.init(
        initLanguageCode: 'en',
        mapLocales: const <MapLocale>[
          MapLocale(
            'en',
            <String, dynamic>{'title': 'Color'},
            countryCode: 'US',
          ),
          MapLocale(
            'en',
            <String, dynamic>{'title': 'Colour'},
            countryCode: 'GB',
          ),
        ],
      ),
      throwsA(_namedArgumentError('initLanguageCode', 'more than one')),
    );
    await _expectSaved(const Locale('en', 'GB'));
  });

  test('malformed startup language is rejected', () async {
    final localization = await _load();

    expect(
      () => localization.init(
        initLanguageCode: 'en-',
        mapLocales: const <MapLocale>[_english],
      ),
      throwsA(
        _namedArgumentError('initLanguageCode', 'Unsupported locale subtag'),
      ),
    );
  });

  test('duplicate map locales are rejected', () async {
    final localization = await _load();

    expect(
      () => localization.init(
        initLanguageCode: 'en',
        mapLocales: const <MapLocale>[_english, _english],
      ),
      throwsA(_namedArgumentError('mapLocales', 'Duplicate locale')),
    );
  });

  test('duplicate json locales are rejected', () async {
    final localization = await _load();

    expect(
      () => localization.init(
        initLanguageCode: 'en',
        source: LocalizationSource.jsonAsset,
        jsonLocales: const <JsonLocale>[
          JsonLocale('en', 'assets/en.json'),
          JsonLocale('en', 'assets/en-copy.json'),
        ],
      ),
      throwsA(_namedArgumentError('jsonLocales', 'Duplicate locale')),
    );
  });

  test('malformed saved locale is removed', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, 'not-json');
    final localization = await _load();

    localization.init(
      initLanguageCode: 'en',
      mapLocales: const <MapLocale>[_english, _japanese],
    );

    expect(localization.currentLocale, const Locale('en'));
    expect(preferences.getString(_preferenceKey), isNull);
  });

  test('translating to an unsupported locale reports configured locales',
      () async {
    final localization = await _load();
    localization.init(
      initLanguageCode: 'en',
      mapLocales: const <MapLocale>[_english, _japanese],
    );

    expect(
      () => localization.translate('fr'),
      throwsA(_namedArgumentError('locale', 'Configured locales: en, ja')),
    );
  });

  testWidgets('unsupported saved locale renders the startup language',
      (WidgetTester tester) async {
    await PreferenceUtil.setLocale(const Locale('de'));
    final localization = await _load();
    localization.init(
      initLanguageCode: 'en',
      mapLocales: const <MapLocale>[_english, _japanese],
    );

    await tester.pumpWidget(_LocalizedApp(localization));
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);
    expect(localization.currentLocale, const Locale('en'));
    await _expectSaved(null);
  });
}

Future<FlutterLocalization> _load() async {
  final localization = FlutterLocalization.instance;
  await localization.ensureInitialized();
  return localization;
}

Future<void> _expectSaved(Locale? locale) async {
  Locale? saved;
  for (var attempt = 0; attempt < 50; attempt++) {
    saved = await PreferenceUtil.getLocale();
    if (saved == locale) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  expect(saved, locale);
}

String _unusedLanguage(Iterable<String> taken) {
  const candidates = <String>['ja', 'km', 'de', 'fr', 'es'];
  final normalized = taken.map((String code) => code.toLowerCase()).toSet();
  return candidates.firstWhere(
    (String code) => !normalized.contains(code),
  );
}

Matcher _namedArgumentError(String name, String messageContains) {
  return isA<ArgumentError>()
      .having((ArgumentError error) => error.name, 'name', name)
      .having(
        (ArgumentError error) => error.message.toString(),
        'message',
        contains(messageContains),
      );
}

class _LocalizedApp extends StatelessWidget {
  const _LocalizedApp(this.localization);

  final FlutterLocalization localization;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localization,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          locale: localization.currentLocale,
          supportedLocales: localization.supportedLocales,
          localizationsDelegates: localization.localizationsDelegates,
          home: const _Home(),
        );
      },
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Text('title'.getString(context)));
  }
}
