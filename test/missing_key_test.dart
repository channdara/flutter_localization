import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
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

  testWidgets(
    'missing translator uses the same fallback as a missing key',
    (tester) async {
      await tester.pumpWidget(const _BareApp());

      expect(find.text('title not found'), findsOneWidget);
      expect(find.text('Hello title, version LATEST.'), findsOneWidget);
      expect(find.textContaining('null'), findsNothing);
    },
  );

  testWidgets(
    'loaded translations keep missing text and replace known keys',
    (tester) async {
      final localization = FlutterLocalization.instance;
      await localization.ensureInitialized();
      localization.init(
        initLanguageCode: 'en',
        mapLocales: const <MapLocale>[
          MapLocale('en', <String, dynamic>{
            'title': 'Localization',
            'message': 'This is %a package, version %a.',
          }),
        ],
      );

      await tester.pumpWidget(_LocalizedApp(localization));
      await tester.pumpAndSettle();

      expect(find.text('Localization'), findsOneWidget);
      expect(find.text('missing not found'), findsOneWidget);
      expect(
        find.text('This is Localization package, version LATEST.'),
        findsOneWidget,
      );
      expect(find.text('Hello missing'), findsOneWidget);
    },
  );
}

class _BareApp extends StatelessWidget {
  const _BareApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (BuildContext context) {
          return Scaffold(
            body: Column(
              children: <Widget>[
                Text('title'.getString(context)),
                Text(
                  context.formatString(
                    'Hello %a, version %a.',
                    <String>['title', 'LATEST'],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
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
          home: const _FormatHome(),
        );
      },
    );
  }
}

class _FormatHome extends StatelessWidget {
  const _FormatHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Text('title'.getString(context)),
          Text('missing'.getString(context)),
          Text(
            context.formatString('message', <String>['title', 'LATEST']),
          ),
          Text(context.formatString('Hello %a', <String>['missing'])),
        ],
      ),
    );
  }
}
