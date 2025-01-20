import 'package:flutter/material.dart';

import '../../flutter_localization.dart';
import '../localization/flutter_localization_translator.dart';
import '../model/context_null_exception.dart';

extension StringExtension on String {
  String get tr {
    final context = FlutterLocalization.instance.navigatorKey.currentContext;
    if (context != null) return getString(context);
    throw const ContextNullException();
  }

  String getString(BuildContext context) {
    return FlutterLocalizationTranslator.of(context)?.getString(this) ??
        '$this not found';
  }
}
