import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'media_picker_plugin_platform_interface.dart';
class MediaPicker {
  static const EventChannel _eventChannel =
      EventChannel('com.example.media_picker/events');

  Stream<dynamic> get mediaPickerEvents =>
      _eventChannel.receiveBroadcastStream();

  static const MethodChannel _methodChannel =
      MethodChannel('com.example.media_picker/methods');

  Future<void> sendEvent(Map<String, dynamic> event) async {
    await _methodChannel.invokeMethod('handleEvent', event);
  }
}

  final MediaPicker _mediaPicker = MediaPicker();
  StreamSubscription? _eventSubscription;
/// An implementation of [MediaPickerPluginPlatform] that uses method channels.
class MethodChannelMediaPickerPlugin extends MediaPickerPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('media_picker_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
