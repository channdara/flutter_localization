import 'package:flutter/material.dart';

extension LocaleExtension on Locale? {
  String get localeIdentifier {
    if (this == null) return '';
    return '${this?.languageCode}_${this?.countryCode}'.replaceAll('_null', '');
  }
}
