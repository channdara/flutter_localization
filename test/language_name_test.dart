import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final localization = FlutterLocalization.instance;

  test('language names are each language own name', () {
    expect(localization.getLanguageName(languageCode: 'en'), 'English');
    expect(localization.getLanguageName(languageCode: 'km'), 'ភាសាខ្មែរ');
    expect(localization.getLanguageName(languageCode: 'ja'), '日本語');
    expect(localization.getLanguageName(languageCode: 'zh'), '中文');
  });

  test('script and country tags do not select a different name', () {
    expect(
      localization.getLanguageName(languageCode: 'zh-Hant'),
      'Name for zh-Hant not found',
    );
    expect(
      localization.getLanguageName(languageCode: 'en-US'),
      'Name for en-US not found',
    );
  });

  test('an unknown language code returns a readable marker', () {
    expect(
      localization.getLanguageName(languageCode: 'zz'),
      'Name for zz not found',
    );
  });
}
