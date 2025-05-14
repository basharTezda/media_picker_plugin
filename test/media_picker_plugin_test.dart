import 'package:flutter_test/flutter_test.dart';
import 'package:media_picker_plugin/media_picker_plugin.dart';
import 'package:media_picker_plugin/media_picker_plugin_platform_interface.dart';
import 'package:media_picker_plugin/media_picker_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMediaPickerPluginPlatform
    with MockPlatformInterfaceMixin
    implements MediaPickerPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MediaPickerPluginPlatform initialPlatform = MediaPickerPluginPlatform.instance;

  test('$MethodChannelMediaPickerPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMediaPickerPlugin>());
  });

  test('getPlatformVersion', () async {
    MediaPickerPlugin mediaPickerPlugin = MediaPickerPlugin();
    MockMediaPickerPluginPlatform fakePlatform = MockMediaPickerPluginPlatform();
    MediaPickerPluginPlatform.instance = fakePlatform;

    expect(await mediaPickerPlugin.getPlatformVersion(), '42');
  });
}
