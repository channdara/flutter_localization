mixin Strings {
  static String format(String fullText, List<dynamic> args) {
    for (final element in args) {
      fullText = fullText.replaceFirst('%a', element.toString());
    }
    return fullText;
  }
}
