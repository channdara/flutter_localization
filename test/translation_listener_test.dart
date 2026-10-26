import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_localization/src/localization/flutter_localization_translator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterLocalizationTranslator.debugReset();
    final FlutterLocalization localization = FlutterLocalization.instance;
    localization.onTranslatedLanguage = null;
    await localization.ensureInitialized();
    localization.init(
      initLanguageCode: 'en',
      mapLocales: const <MapLocale>[
        MapLocale('en', <String, dynamic>{'title': 'Hello'}),
        MapLocale('ja', <String, dynamic>{'title': 'こんにちは'}),
      ],
    );
  });

  tearDown(() {
    FlutterLocalization.instance.onTranslatedLanguage = null;
    FlutterLocalizationTranslator.debugReset();
  });

  test('keeps every listener when the legacy callback is replaced', () {
    final FlutterLocalization localization = FlutterLocalization.instance;
    final heard = <String>[];
    void first() => heard.add('first');
    void second() => heard.add('second');
    localization.addListener(first);
    localization.addListener(second);
    addTearDown(() {
      localization.removeListener(first);
      localization.removeListener(second);
    });

    localization.onTranslatedLanguage =
        (Locale? locale) => heard.add('legacy:${locale?.languageCode}');

    localization.translate('ja', save: false);
    expect(heard, <String>['legacy:ja', 'first', 'second']);

    heard.clear();
    localization.onTranslatedLanguage =
        (Locale? locale) => heard.add('replaced:${locale?.languageCode}');
    localization.translate('en', save: false);
    expect(heard, <String>['replaced:en', 'first', 'second']);

    heard.clear();
    localization.removeListener(first);
    localization.translate('ja', save: false);
    expect(heard, <String>['replaced:ja', 'second']);
  });

  test('notifies listeners when the legacy callback throws', () {
    final FlutterLocalization localization = FlutterLocalization.instance;
    var notified = false;
    void listener() => notified = true;
    localization.addListener(listener);
    addTearDown(() => localization.removeListener(listener));
    localization.onTranslatedLanguage = (Locale? locale) {
      throw StateError('callback failed');
    };

    expect(
      () => localization.translate('ja', save: false),
      throwsStateError,
    );
    expect(notified, isTrue);
    expect(localization.currentLocale, const Locale('ja'));
  });
}
