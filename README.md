# Flutter Localization
Flutter Localization is a package use for in-app localization with Map data.
More easier and faster to implement. This package is inspired by the
**flutter_localizations** itself. Follow the step below to use the package or
checkout a small complete [example](https://pub.dev/packages/flutter_localization/example)
project of the package.

<a href="https://www.buymeacoffee.com/eamchanndara" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>

# How To Use

## Prepare language source (Map<String, dynamic>)
Create a dart file which will contain all the Map data of the locale language your app need.
You can change the file name, class name, and file path whatever you like. Example:
```
mixin AppLocale {
  static const String title = 'title';

  static const Map<String, dynamic> EN = {title: 'Localization'};
  static const Map<String, dynamic> KM = {title: 'ការធ្វើមូលដ្ឋានីយកម្ម'};
  static const Map<String, dynamic> JA = {title: 'ローカリゼーション'};
}
```

## Project configuration
* Initialize the **FlutterLocalization** object (this can be local or global, up to you)
```
final FlutterLocalization localization = FlutterLocalization.instance;
```

* Init the list of **MapLocale** and startup language for the app.
  This has to be done only at the **main.dart** or the first **MaterialApp** in your project.
```
@override
void initState() {
    localization.init(
        mapLocales: [
            const MapLocale('en', AppLocale.EN),
            const MapLocale('km', AppLocale.KM),
            const MapLocale('ja', AppLocale.JA),
        ],
        initLanguageCode: 'en',
    );
    localization.onTranslatedLanguage = _onTranslatedLanguage;
    super.initState();
}

/// the setState function here is a must to add
void _onTranslatedLanguage(Locale? locale) {
    setState(() {});
}
```

* Add **supportedLocales** and **localizationsDelegates** to the **MaterialApp**
```
@override
Widget build(BuildContext context) {
    return MaterialApp(
        supportedLocales: localization.supportedLocales,
        localizationsDelegates: localization.localizationsDelegates,
        home: const SettingsScreen(),
    );
}
```

* Call the **translate** function anytime you want to translate the app and provide it with
  the language code
```
ElevatedButton(
    child: const Text('English'),
    onPressed: () {
        localization.translate('en');
    },
);
```

* To display the value from the Map data, just use the **getString** extension by providing the context
  (the **AppLocale.title** is the constant from mixin class above)
```
AppLocale.title.getString(context);
```

* You also can get the language name too. If you don't specify the language code for the function,
  it will return the language name depend on the current app locale
```
localization.getLanguageName(languageCode: 'en');  // English
localization.getLanguageName(languageCode: 'km');  // ភាសាខ្មែរ
localization.getLanguageName(languageCode: 'ja');  // 日本語

localization.getLanguageName();  // get language name depend on current app locale
```
