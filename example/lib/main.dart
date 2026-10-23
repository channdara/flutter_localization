import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterLocalization.instance.ensureInitialized();
  runApp(const MyApp());
}

mixin AppLocale {
  static const String title = 'title';
  static const String thisIs = 'thisIs';

  // In-memory map data example
  static const Map<String, dynamic> ENGLISH = {
    title: 'Localization',
    thisIs: 'This is %a package, version %a.',
  };
  static const Map<String, dynamic> KHMER = {
    title: 'ការធ្វើមូលដ្ឋានីយកម្ម',
    thisIs: 'នេះគឺជាកញ្ចប់%a កំណែ%a.',
  };
  static const Map<String, dynamic> JAPANESE = {
    title: 'ローカリゼーション',
    thisIs: 'これは%aパッケージ、バージョン%aです。',
  };
}

enum InitializeFor { JSON_ASSET, MAP_DATA }

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterLocalization _localization = FlutterLocalization.instance;
  final InitializeFor _initializeFor = InitializeFor.JSON_ASSET;

  @override
  void initState() {
    super.initState();
    switch (_initializeFor) {
      case InitializeFor.JSON_ASSET:
        _initForJsonLocale();
      case InitializeFor.MAP_DATA:
        _initForMapLocale();
    }
  }

  void _initForJsonLocale() {
    _localization.init(
      initLanguageCode: 'en',
      source: LocalizationSource.jsonAsset,
      jsonLocales: const [
        JsonLocale(
          'en',
          'assets/i18n/en.json',
          countryCode: 'US',
          fontFamily: 'Font EN',
        ),
        JsonLocale(
          'km',
          'assets/i18n/km.json',
          countryCode: 'KH',
          fontFamily: 'Font KM',
        ),
        JsonLocale(
          'ja',
          'assets/i18n/ja.json',
          countryCode: 'JP',
          fontFamily: 'Font JA',
        ),
      ],
    );
  }

  void _initForMapLocale() {
    _localization.init(initLanguageCode: 'en', mapLocales: const [
      MapLocale(
        'en',
        AppLocale.ENGLISH,
        countryCode: 'US',
        fontFamily: 'Font EN',
      ),
      MapLocale(
        'km',
        AppLocale.KHMER,
        countryCode: 'KH',
        fontFamily: 'Font KM',
      ),
      MapLocale(
        'ja',
        AppLocale.JAPANESE,
        countryCode: 'JP',
        fontFamily: 'Font JA',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _localization,
      builder: (context, child) {
        return MaterialApp(
          locale: _localization.currentLocale,
          supportedLocales: _localization.supportedLocales,
          localizationsDelegates: _localization.localizationsDelegates,
          home: const SettingsScreen(),
          theme: ThemeData(fontFamily: _localization.fontFamily),
        );
      },
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FlutterLocalization _localization = FlutterLocalization.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocale.title.getString(context))),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    child: const Text('English'),
                    onPressed: () {
                      _localization.translate('en');
                    },
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton(
                    child: const Text('ភាសាខ្មែរ'),
                    onPressed: () {
                      _localization.translate('km');
                    },
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton(
                    child: const Text('日本語'),
                    onPressed: () {
                      _localization.translate('ja', save: false);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            ItemWidget(
              title: 'Current Language',
              content: _localization.getLanguageName(),
            ),
            ItemWidget(
              title: 'Font Family',
              content: _localization.fontFamily,
            ),
            ItemWidget(
              title: 'Locale Identifier',
              content: _localization.currentLocale.localeIdentifier,
            ),
            ItemWidget(
              title: 'Flutter Locale',
              content: Localizations.localeOf(context).toString(),
            ),
            ItemWidget(
              title: 'String Format',
              content: Strings.format(
                'Hello %a, this is me %a.',
                ['Dara', 'Sopheak'],
              ),
            ),
            ItemWidget(
              title: 'Context Format String',
              content: context.formatString(
                AppLocale.thisIs,
                [AppLocale.title, 'LATEST'],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ItemWidget extends StatelessWidget {
  const ItemWidget({
    super.key,
    required this.title,
    required this.content,
  });

  final String? title;
  final String? content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(title ?? '')),
          const Text(' : '),
          Expanded(child: Text(content ?? '')),
        ],
      ),
    );
  }
}
