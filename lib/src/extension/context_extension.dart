import 'package:flutter/material.dart';

import '../localization/flutter_localization_translator.dart';

extension ContextExtension on BuildContext {
  /// Replaces each `%a` in [fullText] with the next entry in [args].
  ///
  /// [fullText] and every argument are looked up as translation keys. A missing
  /// key, or a context with no translator, keeps that original text. Placeholders
  /// in the resolved format string are still replaced from left to right.
  String formatString(String fullText, List<dynamic> args) {
    final translator = FlutterLocalizationTranslator.of(this);
    var formatted = _textOrKey(translator, fullText);
    for (final element in args) {
      final key = element.toString();
      formatted = formatted.replaceFirst('%a', _textOrKey(translator, key));
    }
    return formatted;
  }
}

/// Returns the translation of [key].
///
/// A missing key and a null [translator] both return [key].
String _textOrKey(FlutterLocalizationTranslator? translator, String key) =>
    translator?.getStringOrKey(key) ?? key;
