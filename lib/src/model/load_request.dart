import 'dart:async';

import '../localization/flutter_localization_translator.dart';

class LoadRequest {
  final Completer<FlutterLocalizationTranslator> _completer =
      Completer<FlutterLocalizationTranslator>();

  Map<String, dynamic>? strings;
  Object? error;
  StackTrace? stackTrace;
  bool settled = false;

  Future<FlutterLocalizationTranslator> get future => _completer.future;

  bool get isReady => strings != null || error != null;

  void fail(Object exception, StackTrace trace) {
    error = exception;
    stackTrace = trace;
  }

  void settle(FlutterLocalizationTranslator translator) {
    settled = true;
    if (_completer.isCompleted) return;
    _completer.complete(translator);
  }

  void settleError(Object exception, StackTrace trace) {
    settled = true;
    error = exception;
    stackTrace = trace;
    if (_completer.isCompleted) return;
    _completer.completeError(exception, trace);
  }
}
