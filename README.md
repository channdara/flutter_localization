# Flutter Localization

Flutter Localization is a Flutter package for in-app localization with **map data** or **JSON assets**. Version 1.0.0 is
a pure Flutter package. It reads the device locale from Flutter's platform dispatcher.

Pass `FlutterLocalization.instance.currentLocale` to `MaterialApp` so your strings, Material and Cupertino labels, text
direction, and `Localizations.localeOf` stay on one locale. The full release history is in [CHANGELOG.md](CHANGELOG.md).
A small [example](https://pub.dev/packages/flutter_localization/example) app is also on pub.dev, and in the `example/`
directory of this repository.

<a href="https://www.buymeacoffee.com/eamchanndara" target="_blank"><img height='40' width='145' style='border:0px;height:40px;' src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me a Coffee" style="height: 60px !important;width: 217px !important;" ></a>
<a href='https://ko-fi.com/J3J3POSKS' target='_blank'><img height='40' width='160' style='border:0px;height:40px;' src='https://storage.ko-fi.com/cdn/kofi5.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

# Breaking Changes in 1.0.0

* The package no longer includes native Android, iOS, or web plugin implementations.
* `FlutterLocalization` now is a `ChangeNotifier`. Rebuild with `ListenableBuilder`, or subscribe with `addListener` and
  `removeListener`.
* `onTranslatedLanguage` is deprecated. Assigning it replaces the previous callback. Listeners registered with
  `addListener` stay in place.
* Locales match on language, script, and country. `translate('en-US')` and `translate('zh-Hant')` select one variant.
  `translateLocale` accepts a `Locale`. A language-only value that matches more than one configured variant throws
  `ArgumentError`.

# How To Use

## Prepare Language Source

At `init` loads one source. Use map data or JSON files, pick one, your choice.

- **Map Data**: fast but use more memory (RAM), recommend for a few locale support
- **JSON File**: slightly slower (not noticeable by eyes), recommend for large amount of locale support

### In-memory Map Data (Map<String, dynamic>)

Create a Dart file for the keys and the map of each locale. File name, class name, and path are up to you.

```dart
mixin AppLocale {
  static const String title = 'title';

  static const Map<String, dynamic> EN = {title: 'Localization'};
  static const Map<String, dynamic> KM = {title: 'ការធ្វើមូលដ្ឋានីយកម្ម'};
  static const Map<String, dynamic> JA = {title: 'ローカリゼーション'};
}
```

### Asset File (JSON assets)

Store one flat JSON object per locale. The asset path is the path you pass to `JsonLocale`. Naming the file after the
locale, such as `assets/i18n/en.json`, keeps the set easy to scan.

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
    - assets/i18n/en.json
    - assets/i18n/km.json
    - assets/i18n/ja.json
```

## Project Configuration

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

`source` chooses the list `init` reads. `LocalizationSource.map` is the default. `init` throws `ArgumentError` when the
locale list is empty, when the same language, script, and country is listed twice, or when `initLanguageCode` cannot be
parsed or matches more than one variant.

### Initialize with In-memory Map Data (Map<String, dynamic>)

```dart
@override
void initState() {
  super.initState();
  localization.init(
    initLanguageCode: 'en',
    source: LocalizationSource.map,
    mapLocales: const [
      MapLocale('en', AppLocale.EN),
      MapLocale('km', AppLocale.KM),
      MapLocale('ja', AppLocale.JA),
    ],
  );
}
```

`source: LocalizationSource.map` is optional here because it is the default.

### Initialize with Asset File (JSON assets)

```dart
@override
void initState() {
  super.initState();
  localization.init(
    initLanguageCode: 'en',
    source: LocalizationSource.jsonAsset,
    jsonLocales: const [
      JsonLocale('en', 'assets/i18n/en.json'),
      JsonLocale('km', 'assets/i18n/km.json'),
      JsonLocale('ja', 'assets/i18n/ja.json'),
    ],
  );
}
```

`init` and `translate` start reading the configured JSON assets, with the active locale first. Each file is decoded once
and kept for later loads. When several loads overlap, the locale selected later is the one that stays on screen. Calling
`init` again with a new map or JSON list reloads strings on the next build.

### Locale Selected at Startup

`initLanguageCode` is the configured startup language, such as `en` or `zh-Hant`. `init` chooses the displayed locale in
this order:

1. The saved locale, when it resolves to one supported locale. A match that changes the script or country is written
   back. A saved locale that does not resolve to one supported locale is removed.
2. `initLanguageCode`, when it matches one supported locale.
3. The platform locale, when it matches one supported locale.
4. The first locale in `mapLocales` or `jsonLocales`.

Tags are parsed by subtag shape. `en` stays language-only. `zh-Hant-TW` keeps its script and country. A POSIX value such
as `en_US.UTF-8` drops the encoding and modifier, then the language, script, and country are read.

## Provide the Locale to MaterialApp

`localizationsDelegates` includes the package delegate plus the Material, Widgets, and Cupertino delegates.
`supportedLocales` is the list from `init`. `locale` has to be `currentLocale`, because the package delegate loads the
locale Flutter asks for.
`fontFamily` is the family of the current locale. It is null when that locale has none. See [Font family](#font-family).

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
        theme: ThemeData(fontFamily: localization.fontFamily),
      );
    },
  );
}
```

### Listen from a State Object (Optional)

`addListener` and `removeListener` support more than one subscriber. Remove the listener when its owner is disposed.
Leave `FlutterLocalization.instance` alive for the process.

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
  // Read localization.currentLocale here.
}
```

`ListenableBuilder` rebuilds `MaterialApp`. A manual listener covers other work that should run when the locale changes.

## Change the Language

The resolved locale is saved. Pass `save: false` to change the language for this session and leave the stored locale
unchanged. A request that resolves to the locale already on screen returns immediately.

### With a language code or locale tag

`translate` accepts a language code or a full tag. Use the full tag when one language has several region or script
variants.

```
ElevatedButton(
  child: const Text('English'),
  onPressed: () {
    localization.translate('en'); // or full tag like en-US, zh-Hant
  },
);
```

### With a Locale object

```
localization.translateLocale(const Locale('en', 'GB'));

localization.translateLocale(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'));
```

### Several variants of one language

`countryCode` and `scriptCode` are optional on both `MapLocale` and `JsonLocale`.

Map data:

```
localization.init(
  initLanguageCode: 'en-US',
  mapLocales: const [
    MapLocale('en', AppLocale.EN_US, countryCode: 'US'),
    MapLocale('en', AppLocale.EN_GB, countryCode: 'GB'),
    MapLocale('zh', AppLocale.ZH_HANT, scriptCode: 'Hant'),
  ],
);
```

JSON file:

```
localization.init(
  initLanguageCode: 'en-US',
  source: LocalizationSource.jsonAsset,
  jsonLocales: const [
    JsonLocale('en', 'assets/i18n/en_US.json', countryCode: 'US'),
    JsonLocale('en', 'assets/i18n/en_GB.json', countryCode: 'GB'),
    JsonLocale('zh', 'assets/i18n/zh_Hant.json', scriptCode: 'Hant'),
  ],
);
```

`translate('en')` throws `ArgumentError` in this setup, because `en` matches both `en_US` and `en_GB`.
`translate('zh-Hant')` matches the single Traditional Chinese entry. `supportedLocales` and `supportedLocaleIdentifiers`
list each configured locale. `supportedLanguageCodes` is the language code of each entry, so `en` can appear more than
once.

## Read a translation

`getString` looks up the key in the translator for this context.

```
AppLocale.title.getString(context);
```

A missing key returns `title not found` when the key is `title`. The same text is returned when the context has no
translator.

## Format text

`%a` is replaced from left to right. A placeholder with no argument stays as `%a`.

### Plain replacement

`Strings.format` inserts each argument with `toString()`.

```
Strings.format('Hello %a, this is me %a.', ['Dara', 'Sopheak']);
// Hello Dara, this is me Sopheak.
```

### Replacement from translation keys

`context.formatString` looks up the format string and each argument as translation keys. A missing key, or a context
with no translator, keeps that original text. Placeholders in the resolved format string are still filled from left to
right.

```
// AppLocale.thisIs == 'thisIs'
// en: 'This is %a package, version %a.'
// AppLocale.title == 'title' -> 'Localization'
context.formatString(AppLocale.thisIs, [AppLocale.title, 'LATEST']);
// This is Localization package, version LATEST.
```

## Font family

`fontFamily` on `MapLocale` or `JsonLocale` is optional. The family can come from
an [asset font](https://docs.flutter.dev/cookbook/design/fonts) or from a package such
as [google_fonts](https://pub.dev/packages/google_fonts).

### Map data

```
MapLocale('en', AppLocale.EN, fontFamily: 'MuseoSans');

MapLocale('en', AppLocale.EN, fontFamily: GoogleFonts.lato().fontFamily);
```

### JSON file

```
JsonLocale('en', 'assets/i18n/en.json', fontFamily: 'MuseoSans');

JsonLocale('km', 'assets/i18n/km.json', countryCode: 'KH', fontFamily: 'Font KM');
```

Read the current family from the same `ListenableBuilder` that rebuilds `MaterialApp`:

```
theme: ThemeData(fontFamily: localization.fontFamily),
```

# More helpers

## Language name

`getLanguageName()` returns the name speakers of that language use for it, such as `English` or `日本語`. Region and
script variants share that language-code name. Omit `languageCode` to use the current locale. An unknown code returns
`Name for <code> not found`.

```
localization.getLanguageName(languageCode: 'en'); // English
localization.getLanguageName(languageCode: 'km'); // ភាសាខ្មែរ
localization.getLanguageName(languageCode: 'ja'); // 日本語

localization.getLanguageName(); // own name of the current language
```

## Locale identifier

`localeIdentifier` joins the language, script, and country with `_`. Script and country are omitted when absent, so the
result can be only the language code. Examples: `en`, `en_US`, `zh_Hant`, `zh_Hant_TW`.

```
localization.currentLocale.localeIdentifier;
```
