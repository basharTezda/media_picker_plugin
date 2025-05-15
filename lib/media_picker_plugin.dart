
import 'media_picker_plugin_platform_interface.dart';
export 'media_picker_plugin_method_channel.dart';

class MediaPickerPlugin {
  Future<void> pickMedia() {
    return MediaPickerPluginPlatform.instance.showMediaPicker();
  }
}
