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

  static const Map<String, dynamic> enUs = {
    title: 'Localization',
    thisIs: 'This is %a package, version %a.',
  };
  static const Map<String, dynamic> khmer = {
    title: 'ការធ្វើមូលដ្ឋានីយកម្ម',
    thisIs: 'នេះគឺជាកញ្ចប់%a កំណែ%a.',
  };
  static const Map<String, dynamic> japanese = {
    title: 'ローカリゼーション',
    thisIs: 'これは%aパッケージ、バージョン%aです。',
  };
  static const Map<String, dynamic> zhHant = {
    title: '在地化',
    thisIs: '這是%a套件，版本%a。',
  };
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterLocalization _localization = FlutterLocalization.instance;
  final LocalizationSource _source = LocalizationSource.jsonAsset;

  @override
  void initState() {
    super.initState();
    switch (_source) {
      case LocalizationSource.jsonAsset:
        _initForJsonLocale();
      case LocalizationSource.map:
        _initForMapLocale();
    }
  }

  void _initForJsonLocale() {
    _localization.init(
      initLanguageCode: 'en-US',
      source: LocalizationSource.jsonAsset,
      jsonLocales: const [
        JsonLocale('en', 'assets/i18n/en_US.json', countryCode: 'US'),
        JsonLocale('km', 'assets/i18n/km.json', countryCode: 'KH'),
        JsonLocale('ja', 'assets/i18n/ja.json', countryCode: 'JP'),
        JsonLocale('zh', 'assets/i18n/zh_Hant.json', scriptCode: 'Hant'),
      ],
    );
  }

  void _initForMapLocale() {
    _localization.init(
      initLanguageCode: 'en-US',
      mapLocales: const [
        MapLocale('en', AppLocale.enUs, countryCode: 'US'),
        MapLocale('km', AppLocale.khmer, countryCode: 'KH'),
        MapLocale('ja', AppLocale.japanese, countryCode: 'JP'),
        MapLocale('zh', AppLocale.zhHant, scriptCode: 'Hant'),
      ],
    );
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
                    child: const Text('English (US)'),
                    onPressed: () {
                      _localization.translate('en-US');
                    },
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: ElevatedButton(
                    child: const Text('ភាសាខ្មែរ'),
                    onPressed: () {
                      _localization.translate('km');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    child: const Text('日本語'),
                    onPressed: () {
                      _localization.translate('ja', save: false);
                    },
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: ElevatedButton(
                    child: const Text('繁體中文'),
                    onPressed: () {
                      _localization.translate('zh-Hant');
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
            ItemWidget(title: 'Font Family', content: _localization.fontFamily),
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
              content: Strings.format('Hello %a, this is me %a.', [
                'Dara',
                'Sopheak',
              ]),
            ),
            ItemWidget(
              title: 'Context Format String',
              content: context.formatString(AppLocale.thisIs, [
                AppLocale.title,
                'LATEST',
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class ItemWidget extends StatelessWidget {
  const ItemWidget({super.key, required this.title, required this.content});

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
