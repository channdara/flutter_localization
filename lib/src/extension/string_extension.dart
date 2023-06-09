import 'package:flutter/material.dart';

import '../localization/flutter_localization_translator.dart';

extension StringExtension on String {
  String getString(BuildContext context) =>
      FlutterLocalizationTranslator.of(context)?.getString(this) ??
      '$this not found';
}
