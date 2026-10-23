# Flutter Localization — Project Analysis

Analysis date: 2026-10-22  
Package version analyzed: `0.4.1`  
Flutter/Dart used for validation: Flutter `3.47.2`, Dart `3.13.2`

## 1. Executive summary

`flutter_localization` is a small Flutter localization plugin that offers:

- in-memory `Map<String, dynamic>` translations;
- translations loaded from JSON assets;
- saved language selection through `shared_preferences`;
- language switching through a singleton service;
- string lookup and positional formatting extensions;
- optional per-language font families;
- built-in Material, Widgets, and Cupertino localization delegates.

The package is easy to understand and its basic language-only use case is compact.
The public entry point is appropriately small, the map and JSON models are
immutable, and the example demonstrates the main workflow.

The main technical concern is that the package's selected locale and Flutter's
application locale are not connected. The package swaps the data loaded by its
custom delegate, but the example does not set `MaterialApp.locale`. As a result,
translated strings can change while `Localizations.localeOf(context)`, text
direction, date/number conventions, and Flutter's built-in widget strings remain
on a different locale.

The next concerns are locale identity and asynchronous loading. Internally,
locales are selected only by `languageCode`, even though `countryCode` and
`scriptCode` are exposed by the API. This makes multiple variants of one language
unsafe. JSON loading also mutates one global translator after asynchronous asset
reads, so rapid language changes can race and display the wrong translation.

There is currently no automated test suite or CI. `flutter analyze` reports three
info-level issues in the example, and `flutter test` cannot run because no
`test/` directory exists. These gaps make behavior changes and cross-platform
releases riskier than necessary.

### Overall assessment

- Product idea: useful for small applications that want a map/JSON API.
- Codebase complexity: low.
- Basic language-only map mode: straightforward.
- Basic language-only JSON mode: functional but repeatedly loads assets.
- Region/script support: exposed but not correctly modeled end to end.
- Flutter locale integration: incomplete.
- Reliability safeguards: limited.
- Test and release maturity: low.
- Recommended priority: fix locale synchronization and locale identity before
  adding more features.

## 2. Repository snapshot

Important project areas:

- `lib/flutter_localization.dart`: public package barrel file.
- `lib/src/localization/flutter_localization.dart`: singleton configuration,
  locale selection, persistence coordination, delegate creation, and fonts.
- `lib/src/localization/flutter_localization_delegate.dart`: Flutter
  `LocalizationsDelegate`.
- `lib/src/localization/flutter_localization_translator.dart`: translation data
  loader and lookup service.
- `lib/src/model/`: map locale, JSON locale, source type, and initialization
  exception.
- `lib/src/extension/`: `BuildContext`, `String`, and nullable `Locale`
  extensions.
- `lib/src/utility/`: preferences and string formatting helpers.
- `lib/src/data/language_name.dart`: built-in language-name catalog.
- `lib/flutter_localization_platform_interface.dart`: platform abstraction.
- `lib/flutter_localization_method_channel.dart`: method-channel implementation.
- `lib/flutter_localization_web.dart`: browser locale implementation.
- `android/`, `ios/`, `linux/`, `macos/`, `windows/`: plugin host code.
- `example/`: six-platform example application.
- `README.md`: main usage documentation.
- `CHANGELOG.md`: release history from `0.0.1` through `0.4.1`.
- `rps.yaml`: dependency-upgrade and publishing shortcuts.
- `analysis_options.yaml`: strict analyzer settings and a large Flutter-style lint
  list.

There is no `test/` directory and no CI configuration under `.github/`.

At analysis time, seven files already had uncommitted changes. This report does
not treat those user changes as defects and does not modify them:

- `analysis_options.yaml`
- `example/analysis_options.yaml`
- `example/linux/flutter/generated_plugins.cmake`
- `example/macos/Podfile`
- `example/macos/Runner.xcodeproj/project.pbxproj`
- `example/windows/flutter/generated_plugins.cmake`
- `pubspec.yaml`

## 3. Package purpose and scope

The package is designed as a lightweight alternative to generated ARB-based
localization. Applications define keys and values directly in Dart maps or JSON
files, then retrieve values at runtime with:

```
AppLocale.title.getString(context);
```

It also supports a simple `%a` placeholder convention:

```
Strings.format('Hello %a', ['Dara']);
context.formatString(AppLocale.message, [AppLocale.title]);
```

The implementation is runtime and key-based. It does not generate typed
localization classes and does not currently provide:

- compile-time missing-key detection;
- plural, gender, or select rules;
- named parameters;
- nested-key traversal;
- locale fallback chains;
- translation-file schema validation;
- deferred locale bundles;
- translator tooling or extraction;
- date, number, or currency formatting.

Those omissions are reasonable for a lightweight package, but they should be
stated clearly so users can choose between this package and Flutter's
`gen_l10n`/ARB ecosystem.

## 4. Public API

The barrel file exports eight APIs:

- `FlutterLocalization`
- `MapLocale`
- `JsonLocale`
- `LocalizationSource`
- `ContextExtension`
- `StringExtension`
- `LocaleExtension`
- `Strings`

### `FlutterLocalization`

`FlutterLocalization.instance` is the process-wide singleton. Its public
operations are:

- `ensureInitialized()`: loads a saved locale or reads the platform locale.
- `init(...)`: configures map or JSON sources and the startup language.
- `translate(languageCode, {save = true})`: changes language and optionally
  persists it.
- `getLanguageName(...)`: reads a language name from the built-in catalog.
- `supportedLanguageCodes`: creates a language-code list.
- `currentLocale`: exposes the selected nullable locale.
- `supportedLocales`: supplies locales to `MaterialApp`.
- `localizationsDelegates`: supplies the custom and Flutter delegates.
- `fontFamily`: resolves the current language's optional font.
- `onTranslatedLanguage`: a single callback used by the application to rebuild.

### Locale models

`MapLocale` contains:

- language code;
- translation map;
- optional country code;
- optional script code;
- optional font family;
- a computed Flutter `Locale`.

`JsonLocale` has the same metadata, replacing map data with an asset path.

Both classes have const constructors and assert that required strings are not
empty. Assertions do not run in release mode, so invalid empty values are not
rejected in production.

### Extensions and helpers

- `String.getString(context)` returns the translated value or
  `"<key> not found"`.
- `BuildContext.formatString(text, args)` translates the format key and each
  argument key, replacing one `%a` per argument.
- nullable `Locale.localeIdentifier` joins non-empty language, script, and
  country subtags with underscores.
- `Strings.format(text, args)` replaces one `%a` for every provided argument.

The formatting API is deliberately small. Extra arguments are ignored after all
placeholders are consumed, and extra placeholders remain in the output. Literal
`%a` escaping is not supported.

## 5. Runtime architecture

### Main components

1. `FlutterLocalization` owns configuration and selected-locale state.
2. `PreferenceUtil` reads and writes the selected `Locale`.
3. `FlutterLocalizationDelegate` plugs the package into Flutter's localization
   system.
4. `FlutterLocalizationTranslator` owns the currently loaded translation map.
5. string/context extensions locate the translator through the widget tree.
6. `onTranslatedLanguage` asks application code to rebuild after a switch.

Both the coordinator and translator are global mutable singletons. This keeps
usage simple but prevents isolated instances, complicates tests, and creates
cross-app/race concerns.

### Initialization flow

Expected consumer sequence:

1. call `WidgetsFlutterBinding.ensureInitialized()`;
2. await `FlutterLocalization.instance.ensureInitialized()`;
3. call `runApp`;
4. call `init(...)` from application state;
5. pass `supportedLocales` and `localizationsDelegates` to `MaterialApp`;
6. rebuild when `onTranslatedLanguage` fires.

`ensureInitialized()` asks `PreferenceUtil` for a saved JSON locale. If none is
saved, it derives a locale from `Platform.localeName`, or from
`navigator.language` on web.

`init(...)` then:

- rejects calls made before `ensureInitialized()`;
- clears supported locales and font data;
- configures either maps or JSON descriptors;
- replaces the current locale with `initLanguageCode` only when no preference
  was found;
- creates a new delegate;
- invokes the rebuild callback.

### Map loading flow

The translator stores the supplied `List<MapLocale>`. When Flutter loads the
delegate, the translator finds the first entry with the same `languageCode` and
assigns its map directly to the global `_string` field.

Benefits:

- synchronous data source;
- no asset I/O;
- no translation-map copy;
- simple lookup.

Costs:

- every locale's map stays in memory;
- source maps remain externally mutable when not declared const;
- selection ignores script and country;
- missing locale data throws through `.first`.

### JSON loading flow

The translator stores the supplied `List<JsonLocale>`. On delegate load, it:

1. finds the first descriptor with the same language code;
2. calls `rootBundle.loadString`;
3. decodes JSON;
4. accepts an object/map at the root;
5. converts non-string keys to strings;
6. stores the result in the same global `_string` field.

There is no explicit cache. A delegate reload can read and decode the same asset
again. Asset-not-found and malformed-JSON exceptions are not converted into
package-specific diagnostics.

### Language switching flow

`translate(languageCode)`:

1. returns immediately if the current language code matches;
2. searches the supported locale list for country and script values;
3. creates a new locale;
4. starts a preference write when `save` is true;
5. replaces the custom delegate;
6. invokes the application callback.

The persistence future is intentionally not awaited because the method returns
`void`. Write failures therefore cannot be observed by the caller.

## 6. Platform implementation

The package is declared as a plugin on Android, iOS, web, Linux, macOS, and
Windows.

### Web

Web is the only platform where the platform abstraction is used for the main
locale flow. It reads `window.navigator.language`. It also exposes the browser
user-agent through the otherwise unused platform-version method.

### iOS and macOS

Native Swift implementations expose platform version and locale. In the current
Dart flow, native `getPlatformLocale` is not called because only web enters the
method-channel path. The locale methods are therefore currently dead behavior.

Both podspecs still contain generated placeholder metadata:

- version `0.0.1`;
- summary/description `"A new Flutter plugin project."`;
- homepage `http://example.com`;
- placeholder author/company and email.

This does not change the Dart package version, but it reduces native package
quality and should be corrected.

Swift Package Manager manifests exist for both platforms.

### Android, Linux, and Windows

These implementations expose only `getPlatformVersion`. They do not implement
`getPlatformLocale`, but the current Dart code does not call that method on
native platforms. Their host code is effectively generated plugin scaffolding
for a method not used by the package's public barrel API.

Android currently targets:

- minimum SDK 21;
- compile SDK 36;
- Java/JVM 17;
- Android Gradle Plugin 9.0.1;
- Kotlin 2.3.20.

These recent build-tool requirements should be tested in CI against the minimum
Flutter version claimed by the package, not only the latest Flutter SDK.

## 7. Persistence behavior

Preferences use one key, `translator_locale_key`, whose value is JSON containing
language, country, and script fields.

Positive properties:

- all locale subtags are retained;
- a language switch can opt out of saving;
- storage format is easy to inspect.

Risks:

- malformed or incompatible stored JSON causes initialization to fail;
- no fallback or cleanup handles a corrupted value;
- a saved locale is accepted before supported locales are known;
- `init(...)` does not verify that the saved locale is supported;
- preference writes are fire-and-forget;
- key names use non-idiomatic snake case and a generic prefix that predates the
  current package API.

A robust initialization should validate the saved locale against configured
locales and fall back predictably to `initLanguageCode`, platform resolution, or
the first supported locale.

## 8. Strengths

- Small and navigable source tree.
- Compact public barrel with no accidental export of internal translator or
  preference classes.
- Const locale descriptors.
- Clear choice between map and JSON sources.
- Supports all Flutter host platforms in the example.
- Uses `Locale.fromSubtags`, allowing script and country values at the model
  boundary.
- Includes Flutter's Material, Widgets, and Cupertino delegates.
- Persists all three locale subtags.
- Provides a missing-key marker instead of silently returning an empty string.
- JSON root maps are normalized to string keys.
- README covers setup, map mode, JSON mode, switching, fonts, language names,
  identifiers, and formatting.
- Changelog records the full package history and breaking initialization change.
- Current direct and development dependencies resolve and are up to date under
  the active SDK.
- `dart pub publish --dry-run` found no package-layout or metadata validation
  errors beyond the dirty-git warning.

## 9. Findings and risks

### Medium: preference writes cannot be observed

`translate` returns `void`, while `PreferenceUtil.setLocale` is asynchronous.
Callers cannot wait for persistence or handle errors.

Recommendation:

- return `Future<void>` from `translate`, or explicitly isolate and report
  persistence errors;
- separate in-memory selection from persistence when API compatibility matters.

### Medium: mutable collections leak into runtime behavior

Map data is assigned directly to the translator. Lists are retained without
defensive copies, and `supportedLocales` exposes the internal list as an
`Iterable`.

Recommendation:

- copy and wrap configuration with unmodifiable collections;
- return `List<Locale>.unmodifiable`;
- document whether dynamic mutation is supported; preferably do not support it.

### Medium: nested JSON and value types are not defined

Any value is converted with `.toString()`. A nested object therefore displays as
a Dart map string instead of supporting a dotted lookup or being rejected.
Numbers and booleans are also silently converted.

Recommendation:

- document JSON as a flat object of string values;
- validate and throw a useful format exception;
- alternatively define and test nested-key behavior.

### Medium: missing-key and uninitialized-context behavior is inconsistent

`String.getString` returns `"<key> not found"` when no translator exists.
`ContextExtension.formatString` interpolates the result of a null-aware call,
which can turn the format text or an argument into the literal string `"null"`.

Recommendation:

- define one missing/unavailable translation policy;
- avoid stringifying null;
- allow a configurable fallback/missing-key callback for debug telemetry.

### Medium: language-name data is global, fixed, and not locale-sensitive

The language-name catalog returns each language's native/autonym-like label.
Names cannot be overridden, region/script variants are ignored, and missing
codes return an English error string. The data also includes questionable legacy
or typo-like entries.

Recommendation:

- type it as `Map<String, String>`;
- make it const and internal;
- allow application overrides;
- clarify that values are self-names, not names localized to the current UI;
- review against a maintained locale dataset.

### Medium: dependency/tool placement can be improved

`yaml` is used only by `lib/script/upgrade_all_dependencies.dart`, not at package
runtime. Keeping the maintenance script under `lib/` causes it to be included in
the published library archive and makes `yaml` a runtime dependency.

Recommendation:

- move the script to `tool/`;
- move `yaml` to `dev_dependencies`;
- consider using `dart pub outdated` and a dependency-update service rather than
  rewriting constraints automatically.

### Medium: maintenance scripts use misleading naming

`rps.yaml` maps its `test` command to `flutter pub publish --dry-run`, not to
`flutter test`. A maintainer can therefore run what appears to be the test suite
without discovering that no tests exist.

Recommendation:

- map `test` to `flutter test`;
- rename the current command to `publish-check` or `dry-run`;
- add analysis and formatting commands so local and CI workflows use the same
  checks.

### Medium: lint configuration is oversized and currently not clean

Both package and example carry a roughly 12 KB lint list copied from Flutter's
repository. It includes repository-specific commentary and rules that are not
tailored to this package.

`flutter analyze` currently reports three `unreachable_from_main` info messages
for the example's unused map constants because the example is configured only
for JSON.

Recommendation:

- use `include: package:flutter_lints/flutter.yaml`;
- add only intentional project-specific rules;
- split map and JSON examples, or ensure both are reachable;
- require zero analyzer findings in CI.

### Medium: documentation has important omissions

The README is useful but does not explain:

- that `MaterialApp.locale` must follow `currentLocale`;
- actual locale fallback behavior;
- unsupported language behavior;
- limitations on duplicate language codes;
- JSON flat-string requirements;
- malformed asset behavior;
- pluralization and formatting limitations;
- preference behavior when supported locales change;
- testing guidance.

The example README is still the default Flutter template and does not describe
this package's example.

Recommendation:

- make one canonical minimal setup snippet compile as written;
- document lifecycle and limitations;
- replace the example README;
- add migration notes for any locale API redesign.

### Low: package metadata can be richer

The pubspec has a homepage and issue tracker but no explicit repository, topics,
funding metadata, screenshots, or documentation URL. The description is
grammatically awkward. The package name is also easy to confuse with Flutter's
official `flutter_localizations` SDK package, so the description should make the
distinction explicit.

Recommendation:

- improve the one-sentence description;
- add `repository`;
- add relevant `topics`;
- consider screenshots/GIFs and a documentation link;
- verify metadata against current pub.dev scoring guidance.

### Low: generated native metadata remains

The iOS/macOS podspec placeholders and generated comments make the native
package look unfinished. `CHANGELOG.md` also says “build-in Kotlin” where
“built-in Kotlin” is intended. The root `LICENSE` retains angle-bracket
placeholder formatting around the copyright year and holder.

Recommendation:

- replace generated podspec metadata with real package information;
- normalize the copyright line while preserving the existing BSD license terms;
- proofread public documentation and changelog text.

### Low: published archive contains avoidable maintainer/IDE files

The publish dry run includes `flutter_localization.iml`, `rps.yaml`, and the
dependency-upgrade script under `lib/script/`. There is no `.pubignore`.

Recommendation:

- add a focused `.pubignore` for IDE and maintainer-only files;
- move scripts out of the public library tree;
- inspect the dry-run archive after changing ignore rules so required example
  and platform files remain included.

### Low: API naming and nullability can be tightened

- `EnsureInitializeException` would read more naturally as
  `EnsureInitializedException` or `NotInitializedException`.
- `EnsureInitializeException` is thrown by public `init()` but is not exported
  by the package barrel, making documented exception handling awkward.
- `currentLocale` remains nullable publicly even after required initialization.
- comments contain small grammar errors such as “base on” and “onl”.
- uppercase map constants in the example conflict with common Dart style.
- the example calls `super.initState()` after its own initialization work rather
  than first, which is unconventional even though the current code works.
- `init` is synchronous even though JSON loading happens later inside the
  delegate, which may surprise consumers.

These are secondary to correctness and should be addressed with deprecations
where public API compatibility is involved.

## 10. Validation results

### `flutter analyze`

Result: failed with three info-level findings.

All three are `unreachable_from_main` in `example/lib/main.dart` for:

- `AppLocale.EN`
- `AppLocale.KM`
- `AppLocale.JA`

The package source itself did not produce an analyzer error in this run.

### `flutter test`

Result: could not run because the repository has no `test/` directory.

### `dart pub publish --dry-run`

Result: package structure validated with one warning.

The warning is that seven checked-in files have uncommitted modifications. The
dry run reported a compressed archive size of approximately 307 KB. No other
package validation issue was reported. The archive includes the IDE module file,
`rps.yaml`, and `lib/script/upgrade_all_dependencies.dart`; these are not
validation errors, but they are candidates for publish cleanup.

### `flutter pub outdated`

Result: all direct and development dependencies are up to date and resolvable
under the current SDK. Two transitive packages have newer versions that are not
currently resolvable through the active dependency graph:

- `material_color_utilities`
- `test_api`

This is informational and does not require direct constraints.

## 11. Recommended target architecture

A safer architecture can remain lightweight:

1. Introduce an immutable `LocalizationConfig`.
2. Represent locale identity with full `Locale` values.
3. Store translation sources by normalized full locale key.
4. Make one immutable translator instance per loaded locale.
5. Cache JSON maps after validation.
6. Make the controller a `ChangeNotifier` or `ValueNotifier<Locale>`.
7. Set `MaterialApp.locale` from that controller.
8. Let the delegate load exactly the locale Flutter passes to it.
9. Define fallback in one place, for example:
    - exact language-script-country;
    - language-script;
    - language-country where appropriate;
    - language;
    - configured fallback locale.
10. Use `platformDispatcher.locale` and remove method channels if feasible.
11. Keep preference storage behind an injectable interface for tests.
12. Expose missing-key and load-error hooks without requiring global state.

A conceptual consumer API could be:

```
final localization = FlutterLocalization(
  fallbackLocale: const Locale('en'),
  locales: [
    JsonLocale(const Locale('en', 'US'), 'assets/i18n/en-US.json'),
    JsonLocale(const Locale('en', 'GB'), 'assets/i18n/en-GB.json'),
  ],
);

await localization.ensureInitialized();

MaterialApp(
  locale: localization.locale,
  supportedLocales: localization.supportedLocales,
  localizationsDelegates:localization.localizationsDelegates,
);
```

This is a design direction, not a requirement to break the API immediately.
Compatibility adapters and deprecations can stage the migration.

## 12. Test plan

### Unit tests

Add tests for:

- `MapLocale` and `JsonLocale` conversion to `Locale`;
- locale identifier output for language-only, script, country, and null;
- `Strings.format` with zero, matching, extra, and missing arguments;
- preference encoding/decoding;
- corrupt preference recovery;
- source-list validation;
- duplicate full locales;
- duplicate language with distinct region/script;
- unknown startup locale;
- unknown translated locale;
- language-name lookup and override behavior;
- JSON root type and value validation;
- malformed JSON;
- missing JSON asset;
- missing keys;
- locale fallback order.

### Widget tests

Verify that:

- map translations render;
- JSON translations render;
- language switching rebuilds;
- `Localizations.localeOf(context)` equals the selected locale;
- Material widget labels switch with package strings;
- RTL direction changes correctly;
- selected font changes;
- saved language restores;
- an unsupported saved locale falls back;
- rapid JSON switches cannot finish out of order.

### Platform and integration checks

At minimum:

- `flutter analyze`;
- `dart format --output=none --set-exit-if-changed .`;
- `flutter test`;
- `dart pub publish --dry-run`;
- `flutter build web`;
- Android example build;
- iOS/macOS validation on macOS;
- Linux/Windows example builds in their native CI environments if the package
  remains a plugin.

Test both:

- minimum declared Flutter/Dart versions;
- current Flutter stable.

## 13. Prioritized roadmap

### Phase 1 — protect current behavior

1. Add tests for existing map and JSON flows.
2. Make analyzer output clean.
3. Add CI.
4. Document current limitations.
5. Update the example to bind `MaterialApp.locale`.
6. Validate unsupported saved and startup locales.

### Phase 2 — fix locale correctness

1. Use full locale identity.
2. Support same-language region/script variants.
3. Define and test fallback.
4. Align the package delegate with Flutter's requested locale.
5. Replace the single callback with listenable state.

### Phase 3 — fix loading and state isolation

1. Replace the mutable translator singleton with per-locale instances.
2. Cache validated JSON maps.
3. Eliminate rapid-switch races.
4. Make persistence awaitable and injectable.
5. Expose structured loading errors.

### Phase 4 — simplify platforms and package

1. Read platform locale from Flutter's platform dispatcher.
2. Remove unused method-channel and native plugin code if compatibility allows.
3. Move maintenance scripts to `tool/`.
4. Move `yaml` to development dependencies.
5. Fix `rps.yaml` command names.
6. Add publish-ignore rules for maintainer and IDE files.
7. Simplify lint configuration.
8. Correct license, podspec, and pubspec metadata.

### Phase 5 — optional product features

Only after correctness and tests:

- configurable missing-key handler;
- locale fallback locale (s);
- named interpolation;
- plural/select support, possibly through `intl`;
- nested JSON keys if there is demand;
- translation completeness validation;
- dev tooling to compare keys across locales.

## 14. Release checklist

Before the next pub.dev release:

- [ ] Decide whether region/script variants are supported.
- [ ] Ensure package locale and Flutter locale always agree.
- [ ] Validate startup, persisted, and requested locales.
- [ ] Add automated tests.
- [ ] Add CI.
- [ ] Reach zero analyzer findings.
- [ ] Run formatter verification.
- [ ] Run tests on minimum and stable Flutter versions.
- [ ] Verify map and JSON examples.
- [ ] Test rapid JSON language switching.
- [ ] Run web and native platform builds.
- [ ] Replace podspec placeholder metadata.
- [ ] Normalize the LICENSE copyright line.
- [ ] Fix `rps.yaml` so `test` runs the actual test suite.
- [ ] Review `.pubignore` and remove avoidable archive files.
- [ ] Update README and example README.
- [ ] Add repository/topics metadata where useful.
- [ ] Update changelog with behavior and migration notes.
- [ ] Run `dart pub publish --dry-run` from a clean working tree.
- [ ] Manually review the archive file list.

## 15. Final conclusion

The project succeeds at presenting a small runtime translation API, and its
source is compact enough to improve without a large rewrite. The highest-value
work is not adding translation features; it is making locale selection correct
and deterministic.

The package should first synchronize with Flutter's actual locale, treat the
full locale as identity, remove the global asynchronous translator race, and
build a test/CI safety net. Once those foundations are in place, platform
simplification and API ergonomics can substantially reduce maintenance while
preserving the package's main advantage: quick map- or JSON-based localization.
