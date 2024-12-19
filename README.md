# Flutter Localization

Flutter Localization is a package use for in-app localization with Map data. Easier and faster to implement. This
package is inspired by the Flutter
SDK [flutter_localizations](https://api.flutter.dev/flutter/flutter_localizations/flutter_localizations-library.html)
itself. Follow the step below to use the package, or you can
check out a small [example](https://pub.dev/packages/flutter_localization/example) project of the package.

<a href="https://www.buymeacoffee.com/eamchanndara"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=&slug=eamchanndara&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff" /></a>
<a href="https://ko-fi.com/eamchanndara" target='_blank'><img height='50' style='border:0px;height:50px;' src='https://storage.ko-fi.com/cdn/kofi5.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

# Break Change

* From version 0.3.0 up, there a major update that break the code in the initialize flow. Please re-check the **Project
  Configuration** section to see more detail of migration from version **0.2** to **0.3**. Don't worry, there's only few
  things to changed and add.

# How To Use

## Prepare language source (Map<String, dynamic>)

Create a dart file which will contain all the Map data of the locale language your app need. You can change the file
name, class name, and file path whatever you like. Example:

```
mixin AppLocale {
  static const String title = 'title';

  static const Map<String, dynamic> EN = {title: 'Localization'};
  static const Map<String, dynamic> KM = {title: 'ការធ្វើមូលដ្ឋានីយកម្ម'};
  static const Map<String, dynamic> JA = {title: 'ローカリゼーション'};
}
```

## Project configuration

* Ensure plugin initialize. Update main function into async function, add **WidgetsFlutterBinding.ensureInitialized()**
  and **await FlutterLocalization.instance.ensureInitialized()** before **runApp()** function like below.

```
Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await FlutterLocalization.instance.ensureInitialized();
    runApp(const MyApp());
}
```

* Initialize the **FlutterLocalization** object (this can be local or global, up to you)

```
final FlutterLocalization localization = FlutterLocalization.instance;
```

* Init the list of **MapLocale** and startup language for the app. This has to be done only at the **main.dart** or the
  **MaterialApp** in your project.

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

// the setState function here is a must to add
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

* Call the **translate** function anytime you want to translate the app and provide it with the language code

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

## Extras

* You also can get the language name too. If you don't specify the language code for the function, it will return the
  language name depend on the current app locale

```
localization.getLanguageName(languageCode: 'en');  // English
localization.getLanguageName(languageCode: 'km');  // ភាសាខ្មែរ
localization.getLanguageName(languageCode: 'ja');  // 日本語

localization.getLanguageName();  // get language name depend on current app locale
```

* If you need to use locale identifier in some case, you can get it from the current locale. The identifier format
  is **languageCode_scriptCode_countryCode**. For **scriptCode** and **countryCode** are optional, this might return
  only the **languageCode**.

```
localization.currentLocale.localeIdentifier;
```

# Some update note

### **Version 0.3.0**

From version 0.3.0 up, there a major update that break the code in the initialize flow. Please re-check the README
document at the beginning of the **Project Configuration** section to see more. The break change related with:

* Update **main** function from **void** to **Future<void> async** for package ensureInitialized function
* Call **ensureInitialized** function to init the core functionality of the package

### **Version 0.1.13**

Added **Strings Util** and **Context Extension** for helping with localization text that are dynamic base on language.
Check the usage below or the [example](https://pub.dev/packages/flutter_localization/example) here.

As for **Strings Util**, it just formats string normally from the **list of arguments** to the **full text** string.

```
Strings.format('Hello %a, this is me %a.', ['Dara', 'Sopheak']);
// Result: Hello Dara, this is me Sopheak.
```

As for **Context Extension**, the full text and arguments you provide, will use to check and get data from the string
source. If the result is null, it will return the key that use to get the resource string.

```
context.formatString('This is %a package, version %a.', [AppLocale.title, 'LATEST'])
// Result: This is Localization package, version LATEST.
```

### **Version 0.1.11**

You can provide the font family in the **MapLocale** model at the **init()** function that
can be from [Assets](https://docs.flutter.dev/cookbook/design/fonts)
or [GoogleFonts](https://pub.dev/packages/google_fonts) package.

```
// font family from asset
MapLocale('en', AppLocale.EN, fontFamily: 'MuseoSans');

// or from GoogleFonts package
MapLocale('en', AppLocale.EN, fontFamily: GoogleFonts.lato().fontFamily);
```

Lastly, provide the font family to the MaterialApp's ThemeData

```
@override
Widget build(BuildContext context) {
    return MaterialApp(
        supportedLocales: localization.supportedLocales,
        localizationsDelegates: localization.localizationsDelegates,
        home: const SettingsScreen(),
        theme: ThemeData(fontFamily: localization.fontFamily),
    );
}
```
