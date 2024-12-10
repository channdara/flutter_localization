import 'package:flutter/material.dart';

extension LocaleExtension on Locale? {
  String get localeIdentifier {
    return [
      this?.languageCode ?? '',
      this?.scriptCode ?? '',
      this?.countryCode ?? '',
    ].where((element) => element.isNotEmpty).join('_');
  }
}
