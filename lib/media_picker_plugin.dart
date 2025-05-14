
import 'media_picker_plugin_platform_interface.dart';

class MediaPickerPlugin {
  Future<String?> getPlatformVersion() {
    return MediaPickerPluginPlatform.instance.getPlatformVersion();
  }
}
