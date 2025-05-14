import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'media_picker_plugin_method_channel.dart';

abstract class MediaPickerPluginPlatform extends PlatformInterface {
  /// Constructs a MediaPickerPluginPlatform.
  MediaPickerPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static MediaPickerPluginPlatform _instance = MethodChannelMediaPickerPlugin();

  /// The default instance of [MediaPickerPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelMediaPickerPlugin].
  static MediaPickerPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MediaPickerPluginPlatform] when
  /// they register themselves.
  static set instance(MediaPickerPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
