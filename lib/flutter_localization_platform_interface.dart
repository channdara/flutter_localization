import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_localization_method_channel.dart';

abstract class FlutterLocalizationPlatform extends PlatformInterface {
  /// Constructs a FlutterLocalizationPlatform.
  FlutterLocalizationPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterLocalizationPlatform _instance =
      MethodChannelFlutterLocalization();

  /// The default instance of [FlutterLocalizationPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterLocalization].
  static FlutterLocalizationPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterLocalizationPlatform] when
  /// they register themselves.
  static set instance(FlutterLocalizationPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
