#include "include/flutter_localization/flutter_localization_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_localization_plugin.h"

void FlutterLocalizationPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_localization::FlutterLocalizationPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
