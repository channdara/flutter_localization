import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('package locale and Flutter locale stay aligned', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final FlutterLocalization localization = FlutterLocalization.instance;
    await localization.ensureInitialized();
    localization.init(
      initLanguageCode: 'en',
      mapLocales: const <MapLocale>[
        MapLocale('en', <String, dynamic>{'title': 'Hello'}, countryCode: 'US'),
        MapLocale('ja', <String, dynamic>{'title': 'こんにちは'}, countryCode: 'JP'),
        MapLocale('ar', <String, dynamic>{'title': 'مرحبا'}, countryCode: 'SA'),
      ],
    );

    await tester.pumpWidget(_LocalizedApp(localization));
    await tester.pumpAndSettle();

    _expectLocale(
      tester,
      displayed: 'Hello',
      locale: const Locale('en', 'US'),
      textDirection: TextDirection.ltr,
      cancelLabel: 'Cancel',
    );

    localization.translate('ja', save: false);
    await tester.pumpAndSettle();

    _expectLocale(
      tester,
      displayed: 'こんにちは',
      locale: const Locale('ja', 'JP'),
      textDirection: TextDirection.ltr,
      cancelLabel: 'キャンセル',
    );

    localization.translate('ar', save: false);
    await tester.pumpAndSettle();

    _expectLocale(
      tester,
      displayed: 'مرحبا',
      locale: const Locale('ar', 'SA'),
      textDirection: TextDirection.rtl,
      cancelLabel: 'الإلغاء',
    );
  });

  testWidgets('region variants keep distinct translations and fonts',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final FlutterLocalization localization = FlutterLocalization.instance;
    await localization.ensureInitialized();
    localization.init(
      initLanguageCode: 'en-US',
      mapLocales: const <MapLocale>[
        MapLocale(
          'en',
          <String, dynamic>{'title': 'Color'},
          countryCode: 'US',
          fontFamily: 'UsFont',
        ),
        MapLocale(
          'en',
          <String, dynamic>{'title': 'Colour'},
          countryCode: 'GB',
          fontFamily: 'GbFont',
        ),
      ],
    );

    await tester.pumpWidget(_LocalizedApp(localization));
    await tester.pumpAndSettle();

    expect(find.text('Color'), findsOneWidget);
    expect(localization.currentLocale, const Locale('en', 'US'));
    expect(localization.fontFamily, 'UsFont');
    expect(localization.supportedLocaleIdentifiers, <String>['en_US', 'en_GB']);

    localization.translate('en-GB', save: false);
    await tester.pumpAndSettle();

    expect(find.text('Colour'), findsOneWidget);
    expect(localization.currentLocale, const Locale('en', 'GB'));
    expect(localization.fontFamily, 'GbFont');
    expect(
      () => localization.translate('en', save: false),
      throwsArgumentError,
    );
  });

  testWidgets('script variants keep distinct locale identities',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final FlutterLocalization localization = FlutterLocalization.instance;
    await localization.ensureInitialized();
    localization.init(
      initLanguageCode: 'zh-Hans',
      mapLocales: const <MapLocale>[
        MapLocale(
          'zh',
          <String, dynamic>{'title': '简体'},
          scriptCode: 'Hans',
        ),
        MapLocale(
          'zh',
          <String, dynamic>{'title': '繁體'},
          scriptCode: 'Hant',
        ),
      ],
    );

    await tester.pumpWidget(_LocalizedApp(localization));
    await tester.pumpAndSettle();
    expect(find.text('简体'), findsOneWidget);

    localization.translateLocale(
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      save: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('繁體'), findsOneWidget);
    expect(localization.currentLocale?.scriptCode, 'Hant');
  });
}

void _expectLocale(
  WidgetTester tester, {
  required String displayed,
  required Locale locale,
  required TextDirection textDirection,
  required String cancelLabel,
}) {
  final BuildContext context = tester.element(find.text(displayed));
  expect(Localizations.localeOf(context), locale);
  expect(Directionality.of(context), textDirection);
  expect(MaterialLocalizations.of(context).cancelButtonLabel, cancelLabel);
  expect(
    FlutterLocalization.instance.currentLocale,
    locale,
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
