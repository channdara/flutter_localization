import 'package:flutter/material.dart';

extension LocaleExtension on Locale? {
  String get localeIdentifier {
    return [this?.languageCode, this?.countryCode]
        .whereType<String>()
        .join('_');
  }
}
