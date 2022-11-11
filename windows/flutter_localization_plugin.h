#ifndef FLUTTER_PLUGIN_FLUTTER_LOCALIZATION_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_LOCALIZATION_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace flutter_localization {

class FlutterLocalizationPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterLocalizationPlugin();

  virtual ~FlutterLocalizationPlugin();

  // Disallow copy and assign.
  FlutterLocalizationPlugin(const FlutterLocalizationPlugin&) = delete;
  FlutterLocalizationPlugin& operator=(const FlutterLocalizationPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flutter_localization

#endif  // FLUTTER_PLUGIN_FLUTTER_LOCALIZATION_PLUGIN_H_
