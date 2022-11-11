import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_localization_platform_interface.dart';

/// An implementation of [FlutterLocalizationPlatform] that uses method channels.
class MethodChannelFlutterLocalization extends FlutterLocalizationPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_localization');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
