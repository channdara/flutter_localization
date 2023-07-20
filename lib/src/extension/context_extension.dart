import 'package:flutter/material.dart';

import '../localization/flutter_localization_translator.dart';

extension ContextExtension on BuildContext {
  String formatString(String fullText, List<dynamic> args) {
    final translator = FlutterLocalizationTranslator.of(this);
    fullText = '${translator?.getStringOrKey(fullText)}';
    for (final element in args) {
      final replace = '${translator?.getStringOrKey(element.toString())}';
      fullText = fullText.replaceFirst('%a', replace);
    }
    return fullText;
  }
}
