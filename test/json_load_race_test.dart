import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_localization/src/localization/flutter_localization_delegate.dart';
import 'package:flutter_localization/src/localization/flutter_localization_translator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterLocalizationTranslator.debugReset();
  });

  tearDown(FlutterLocalizationTranslator.debugReset);

  test('map snapshots stay independent after later loads and edits', () async {
    final data = <String, dynamic>{'title': 'Hello'};
    final translator = FlutterLocalizationTranslator.instance;
    translator.mapLocales(<MapLocale>[
      MapLocale('en', data),
      const MapLocale('ja', <String, dynamic>{'title': 'こんにちは'}),
    ]);

    final english = await translator.load(const Locale('en'));
    final japanese = await translator.load(const Locale('ja'));
    data['title'] = 'Changed';

    expect(english.getString('title'), 'Hello');
    expect(japanese.getString('title'), 'こんにちは');
  });

  test('JSON is cached separately for each full locale', () async {
    var reads = 0;
    FlutterLocalizationTranslator.debugSetAssetLoader((String path) async {
      reads += 1;
      return path.endsWith('en-GB.json')
          ? '{"title":"Colour"}'
          : '{"title":"Color"}';
    });
    final translator = FlutterLocalizationTranslator.instance;
    translator.jsonLocales(const <JsonLocale>[
      JsonLocale('en', 'assets/en-US.json', countryCode: 'US'),
      JsonLocale('en', 'assets/en-GB.json', countryCode: 'GB'),
    ]);

    expect(
      (await translator.load(const Locale('en', 'US'))).getString('title'),
      'Color',
    );
    expect(
      (await translator.load(const Locale('en', 'US'))).getString('title'),
      'Color',
    );
    expect(
      (await translator.load(const Locale('en', 'GB'))).getString('title'),
      'Colour',
    );
    expect(reads, 2);
  });

  test('delegate reloads only when translation sources change', () {
    final before = FlutterLocalizationDelegate(
      FlutterLocalizationTranslator.configurationId,
    );
    FlutterLocalizationTranslator.instance.mapLocales(<MapLocale>[
      const MapLocale('en', <String, dynamic>{'title': 'Hello'}),
    ]);
    final after = FlutterLocalizationDelegate(
      FlutterLocalizationTranslator.configurationId,
    );

    expect(after.shouldReload(before), isTrue);
    expect(
      after.shouldReload(
        FlutterLocalizationDelegate(
          FlutterLocalizationTranslator.configurationId,
        ),
      ),
      isFalse,
    );
  });

  test('JSON preload reads the startup locale before the other assets',
      () async {
    final reads = <String>[];
    FlutterLocalizationTranslator.debugSetAssetLoader((String path) async {
      reads.add(path);
      return '{"title":"ok"}';
    });
    final localization = FlutterLocalization.instance;
    await localization.ensureInitialized();
    localization.init(
      initLanguageCode: 'ja',
      source: LocalizationSource.jsonAsset,
      jsonLocales: const <JsonLocale>[
        JsonLocale('en', 'assets/en.json'),
        JsonLocale('ja', 'assets/ja.json'),
      ],
    );

    expect(reads, <String>['assets/ja.json', 'assets/en.json']);
    expect(
      (await FlutterLocalizationTranslator.instance.load(const Locale('en')))
          .getString('title'),
      'ok',
    );
    expect(reads, <String>['assets/ja.json', 'assets/en.json']);
  });

  test('a slower JSON load cannot replace the locale selected later', () async {
    final assets = <String, Completer<String>>{};
    FlutterLocalizationTranslator.debugSetAssetLoader((String path) {
      return (assets[path] ??= Completer<String>()).future;
    });
    final translator = FlutterLocalizationTranslator.instance;
    translator.jsonLocales(const <JsonLocale>[
      JsonLocale('ja', 'assets/ja.json'),
      JsonLocale('de', 'assets/de.json'),
    ]);

    final japaneseLoad = translator.load(const Locale('ja'));
    final germanLoad = translator.load(const Locale('de'));

    assets['assets/de.json']!.complete('{"title":"Hallo"}');
    final german = await germanLoad;
    final superseded = await japaneseLoad;

    assets['assets/ja.json']!.complete('{"title":"こんにちは"}');
    await pumpEventQueue();

    expect(german.getString('title'), 'Hallo');
    expect(superseded.getString('title'), 'Hallo');
    expect(
      (await translator.load(const Locale('ja'))).getString('title'),
      'こんにちは',
    );
    expect(german.getString('title'), 'Hallo');
  });

  test('an older configuration cannot refill the JSON cache', () async {
    final reads = <Completer<String>>[];
    FlutterLocalizationTranslator.debugSetAssetLoader((String path) {
      final completer = Completer<String>();
      reads.add(completer);
      return completer.future;
    });
    final translator = FlutterLocalizationTranslator.instance;
    translator.jsonLocales(const <JsonLocale>[
      JsonLocale('en', 'assets/en.json'),
    ]);
    final stale = translator.load(const Locale('en'));

    translator.jsonLocales(const <JsonLocale>[
      JsonLocale('en', 'assets/en.json'),
    ]);
    final fresh = translator.load(const Locale('en'));

    reads[0].complete('{"title":"stale"}');
    reads[1].complete('{"title":"fresh"}');

    expect((await fresh).getString('title'), 'fresh');
    expect((await stale).getString('title'), 'fresh');
    expect(
      (await translator.load(const Locale('en'))).getString('title'),
      'fresh',
    );
    expect(reads, hasLength(2));
  });

  test('malformed JSON fails the load', () async {
    FlutterLocalizationTranslator.debugSetAssetLoader(
      (String path) async => '{',
    );
    FlutterLocalizationTranslator.instance.jsonLocales(const <JsonLocale>[
      JsonLocale('en', 'assets/en.json'),
    ]);

    await expectLater(
      FlutterLocalizationTranslator.instance.load(const Locale('en')),
      throwsFormatException,
    );
  });

  testWidgets('a slower asset cannot win after a newer language is selected', (
    tester,
  ) async {
    final assets = <String, Completer<String>>{};
    FlutterLocalizationTranslator.debugSetAssetLoader((String path) {
      return (assets[path] ??= Completer<String>()).future;
    });
    final localization = FlutterLocalization.instance;
    await localization.ensureInitialized();
    localization.init(
      initLanguageCode: 'en',
      source: LocalizationSource.jsonAsset,
      jsonLocales: const <JsonLocale>[
        JsonLocale('en', 'assets/en.json'),
        JsonLocale('ja', 'assets/ja.json'),
        JsonLocale('de', 'assets/de.json'),
      ],
    );

    await tester.pumpWidget(_LocalizedApp(localization));
    assets['assets/en.json']!.complete('{"title":"Hello"}');
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsOneWidget);

    localization.translate('ja', save: false);
    await tester.pump();
    localization.translate('de', save: false);
    await tester.pump();

    assets['assets/de.json']!.complete('{"title":"Hallo"}');
    await tester.pump();
    await tester.pump();
    expect(find.text('Hallo'), findsOneWidget);
    expect(_localeOf(tester, 'Hallo'), const Locale('de'));

    assets['assets/ja.json']!.complete('{"title":"こんにちは"}');
    await tester.pump();
    await tester.pump();

    expect(find.text('Hallo'), findsOneWidget);
    expect(find.text('こんにちは'), findsNothing);
    expect(_localeOf(tester, 'Hallo'), const Locale('de'));
    expect(localization.currentLocale, const Locale('de'));
  });

  testWidgets(
      'an earlier asset is not shown when a later switch is still loading', (
    tester,
  ) async {
    final assets = <String, Completer<String>>{};
    FlutterLocalizationTranslator.debugSetAssetLoader((String path) {
      return (assets[path] ??= Completer<String>()).future;
    });
    final localization = FlutterLocalization.instance;
    await localization.ensureInitialized();
    localization.init(
      initLanguageCode: 'en',
      source: LocalizationSource.jsonAsset,
      jsonLocales: const <JsonLocale>[
        JsonLocale('en', 'assets/en.json'),
        JsonLocale('ja', 'assets/ja.json'),
        JsonLocale('de', 'assets/de.json'),
      ],
    );

    await tester.pumpWidget(_LocalizedApp(localization));
    assets['assets/en.json']!.complete('{"title":"Hello"}');
    await tester.pumpAndSettle();

    localization.translate('ja', save: false);
    await tester.pump();
    localization.translate('de', save: false);
    await tester.pump();

    assets['assets/ja.json']!.complete('{"title":"こんにちは"}');
    await tester.pump();
    await tester.pump();

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('こんにちは'), findsNothing);
    expect(localization.currentLocale, const Locale('de'));

    assets['assets/de.json']!.complete('{"title":"Hallo"}');
    await tester.pump();
    await tester.pump();

    expect(find.text('Hallo'), findsOneWidget);
    expect(find.text('こんにちは'), findsNothing);
    expect(_localeOf(tester, 'Hallo'), const Locale('de'));
  });

  testWidgets('rebuilding with the same locale does not reload JSON', (
    tester,
  ) async {
    var reads = 0;
    FlutterLocalizationTranslator.debugSetAssetLoader((String path) async {
      reads += 1;
      return path.endsWith('ja.json')
          ? '{"title":"こんにちは"}'
          : '{"title":"Hello"}';
    });
    final localization = FlutterLocalization.instance;
    await localization.ensureInitialized();
    localization.init(
      initLanguageCode: 'en',
      source: LocalizationSource.jsonAsset,
      jsonLocales: const <JsonLocale>[
        JsonLocale('en', 'assets/en.json'),
        JsonLocale('ja', 'assets/ja.json'),
      ],
    );

    await tester.pumpWidget(_LocalizedApp(localization));
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsOneWidget);
    final first = FlutterLocalizationTranslator.of(
      tester.element(find.text('Hello')),
    );
    final readsAfterLoad = reads;

    await tester.pumpWidget(_LocalizedApp(localization));
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);
    expect(reads, readsAfterLoad);
    expect(
      identical(
        first,
        FlutterLocalizationTranslator.of(
          tester.element(find.text('Hello')),
        ),
      ),
      isTrue,
    );

    localization.translate('ja', save: false);
    await tester.pumpAndSettle();

    expect(find.text('こんにちは'), findsOneWidget);
    expect(reads, readsAfterLoad);
  });
}

Locale _localeOf(WidgetTester tester, String text) {
  return Localizations.localeOf(tester.element(find.text(text)));
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
