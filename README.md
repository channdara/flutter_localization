# Flutter Localization

Flutter Localization is a package used for in-app localization with **Map data** or **JSON assets**. It is designed to
be easy and fast to implement. This package is inspired by the Flutter
SDK [flutter_localizations](https://api.flutter.dev/flutter/flutter_localizations/flutter_localizations-library.html)
itself. Follow the steps below to use the package, or you can check out a
small [example](https://pub.dev/packages/flutter_localization/example) project of the package.

<a href="https://www.buymeacoffee.com/eamchanndara" target="_blank"><img height='40' width='145' style='border:0px;height:40px;' src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me a Coffee" style="height: 60px !important;width: 217px !important;" ></a>
<a href='https://ko-fi.com/J3J3POSKS' target='_blank'><img height='40' width='160' style='border:0px;height:40px;' src='https://storage.ko-fi.com/cdn/kofi5.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

---

# Breaking Changes in 1.0.0

* The package no longer includes native Android, iOS, or web plugin implementations.
* `FlutterLocalization` now is a `ChangeNotifier`. Rebuild with `ListenableBuilder`, or subscribe with `addListener` and
  `removeListener`.
* `onTranslatedLanguage` is deprecated. Assigning it replaces the previous callback. Listeners registered with
  `addListener` stay in place.
* Locales match on language, script, and country. `translate('en-US')` and `translate('zh-Hant')` select one variant.
  `translateLocale` accepts a `Locale`. A language-only value that matches more than one configured variant throws
  `ArgumentError`.

---

# Prepare Language Source (Pick One)

- **In-memory Map Data**: fast but use more memory (RAM), recommend for a few locale support.
  Create a Dart file for the keys and the map of each locale. File name, class name, and path are up to you.

```dart
mixin AppLocale {
  static const String title = 'title';

  static const Map<String, dynamic> enUs = {title: 'Localization'};
  static const Map<String, dynamic> khmer = {title: 'ការធ្វើមូលដ្ឋានីយកម្ម'};
  static const Map<String, dynamic> japanese = {title: 'ローカリゼーション'};
  static const Map<String, dynamic> zhHant = {title: '在地化'};
}
```

- **JSON Asset File**: slightly slower (not noticeable by eyes), recommend for large amount of locale support.
  Store one flat JSON object per locale. The asset path is the path you pass to `JsonLocale`. Naming the file after the
  locale, such as `assets/i18n/en_US.json`, keeps the set easy to scan.

```json
{
  "title": "Localization"
}
```

Every value must be a string. A nested object, array, number, boolean, or null fails that file's load with
`FormatException`. Declare the files in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/i18n/en_US.json
    - assets/i18n/km.json
    - assets/i18n/ja.json
    - assets/i18n/zh_Hant.json
```

---

# Project Configuration

Make sure `main` is async. Call `WidgetsFlutterBinding.ensureInitialized()` and
`FlutterLocalization.instance.ensureInitialized()` before `runApp`. `ensureInitialized` loads a saved locale, or the
platform locale when nothing is saved. An unreadable saved value is removed. `init` throws `EnsureInitializedException`
when this step was skipped.

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterLocalization.instance.ensureInitialized();
  runApp(const MyApp());
}
```

Keep the shared instance and call `init` before the first `MaterialApp` build. `initState` is a typical place.

```dart
final FlutterLocalization localization = FlutterLocalization.instance;
```

## Initialize

The `source` chooses the list `init` reads. `init` throws `ArgumentError` when the locale list is empty, when the same
language, script, and country is listed twice, or when `initLanguageCode` cannot be parsed or matches more than one
variant. `countryCode` and `scriptCode` are optional on `MapLocale` and `JsonLocale`.

- Initialize for **In-memory Map Data**

```dart
@override
void initState() {
  super.initState();
  localization.init(
    initLanguageCode: 'en-US',
    source: LocalizationSource.map,
    mapLocales: const [
      MapLocale('en', AppLocale.enUs, countryCode: 'US'),
      MapLocale('km', AppLocale.khmer, countryCode: 'KH'),
      MapLocale('ja', AppLocale.japanese, countryCode: 'JP'),
      MapLocale('zh', AppLocale.zhHant, scriptCode: 'Hant'),
    ],
  );
}
```

- Initialize for **JSON Asset File**

```dart
@override
void initState() {
  super.initState();
  localization.init(
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
```

The `init` and `translate` start reading the configured JSON assets, with the active locale first. Each file is
decoded once and kept for later loads. When several loads overlap, the locale selected later is the one that stays on
screen. Calling `init` again with a new map or JSON list reloads strings on the next build.

## Provide the Locale to MaterialApp

`localizationsDelegates` includes the package delegate plus the Material, Widgets, and Cupertino delegates.
`supportedLocales` is the list from `init`. `locale` has to be `currentLocale`, because the package delegate loads the
locale Flutter asks for. `fontFamily` is the family of the current locale. It is null when that locale has none.
See [Font family](#font-family).

```dart
@override
Widget build(BuildContext context) {
  return ListenableBuilder(
    listenable: localization,
    builder: (context, child) {
      return MaterialApp(
        locale: localization.currentLocale,
        supportedLocales: localization.supportedLocales,
        localizationsDelegates: localization.localizationsDelegates,
        home: const SettingsScreen(),
      );
    },
  );
}
```

**OPTIONAL**: Listen from a State Object. `addListener` and `removeListener` support more than one subscriber. Remove
the listener when its owner is disposed. Leave `FlutterLocalization.instance` alive for the process. `ListenableBuilder`
rebuilds `MaterialApp`, a manual listener covers other work that should run when the locale changes.

```dart
@override
void initState() {
  super.initState();
  localization.addListener(_onLocaleChanged);
}

@override
void dispose() {
  localization.removeListener(_onLocaleChanged);
  super.dispose();
}

void _onLocaleChanged() {
  // Proceed at your discretion.
}
```

## Change the Language

The resolved locale is saved automatically, but you can pass `save: false` to prevent this. A request that resolves to
the locale already on screen returns immediately. There are 2 functions for this:

- `translate` accepts a language code or a full tag.
- `translateLocale` accept a Locale object.

```dart
localization.translate('en'); // or full tag like en-US, zh-Hant

localization.translateLocale(const Locale('en', 'GB'));

localization.translateLocale(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'));
```

## Read a Localization

The `getString` looks up the key in the translator for this context.

```dart
AppLocale.title.getString(context);
```

A missing key returns `title not found` when the key is `title`. The same text is returned when the context has no
translator.

---

# More Helpers

## Format Text

- **Plain Text Replacement**: The `%a` is replaced from left to right. A placeholder with no argument stays as `%a`.
  `Strings.format` inserts each argument with `toString()`.

```dart
Strings.format('Hello %a, this is me %a.', ['Dara', 'Sopheak']);
// Hello Dara, this is me Sopheak
```

- **Replacement from translation keys**: `context.formatString` looks up the format string and each argument as
  translation keys. A missing key, or a context with no translator, keeps that original text. Placeholders in the
  resolved format string are still filled from left to right.

```dart
// AppLocale.thisIs == 'thisIs'
// en: 'This is %a package, version %a.'
// AppLocale.title == 'title' -> 'Localization'
context.formatString(AppLocale.thisIs, [AppLocale.title, 'LATEST']);
// This is Localization package, version LATEST.
```

## Language Name

`getLanguageName()` returns the name speakers of that language use for it, such as `English` or `日本語`. Region and
script variants share that language-code name. Omit `languageCode` to use the current locale. An unknown code returns
`Name for <code> not found`.

```dart
localization.getLanguageName(languageCode: 'en'); // English
localization.getLanguageName(languageCode: 'km'); // ភាសាខ្មែរ
localization.getLanguageName(languageCode: 'ja'); // 日本語

localization.getLanguageName(); // own name of the current language
```

## Locale Identifier

`localeIdentifier` joins the language, script, and country with `_`. Script and country are omitted when absent, so the
result can be only the language code. Examples: `en`, `en_US`, `zh_Hant`, `zh_Hant_TW`.

```dart
localization.currentLocale.localeIdentifier;
```

## Font Family

`fontFamily` on `MapLocale` or `JsonLocale` is optional. The family can come from
an [asset font](https://docs.flutter.dev/cookbook/design/fonts) or from a package such
as [google_fonts](https://pub.dev/packages/google_fonts).

### Map data

```dart
MapLocale('en', AppLocale.EN, fontFamily: 'MuseoSans');

MapLocale('en', AppLocale.EN, fontFamily: GoogleFonts.lato().fontFamily);
```

### JSON file

```dart
JsonLocale('en', 'assets/i18n/en.json', fontFamily: 'MuseoSans');

JsonLocale('km', 'assets/i18n/km.json', countryCode: 'KH', fontFamily: 'Font KM');
```

Read the current family from the same `ListenableBuilder` that rebuilds `MaterialApp`:

```dart
theme: ThemeData(fontFamily: localization.fontFamily),
```

---