import 'package:flutter/material.dart';

import '../localization/flutter_localization_translator.dart';

extension StringExtension on String {
  /// Returns the translation stored for this key.
  ///
  /// A missing key, and a [context] that has no translator, both return
  /// `key not found`, where `key` is this string.
  String getString(BuildContext context) =>
      FlutterLocalizationTranslator.of(context)?.getString(this) ??
      '$this not found';
}
