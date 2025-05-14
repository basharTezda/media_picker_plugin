import 'dart:async';

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

   Future<void> _showMediaPicker(
      {String? user,
      ChatController? chatController,
      RecorderNotifier? notifier,
      ChatRoom? room,
      TextEditingController? textEditingController,
      context}) async {
    _eventSubscription = _mediaPicker.mediaPickerEvents.listen((event) {
      if (event['event'] == 'mediaSelected') {
        selectedMediaPaths = List<String>.from(event['paths']);
        controllerString = event['controller'];
        method = event['method'];
        textEditingController!.text = controllerString;
        if (method == "send") {
          state = state.copyWith(
            mediaFileSelected: true,
            displayFile: selectedMediaPaths.map((toElement) {
              return File(toElement);
            }).toList(),
            chosenFile: File(selectedMediaPaths.first),
            isVideoFile: true,
          );
          sendMediaFile(
              user: user,
              textEditingController: textEditingController,
              chatController: chatController,
              room: room,
              notifier: notifier,
              context: context);
          textEditingController.clear();
        } else {
          _openEditor(
            images: selectedMediaPaths,
            user: user,
            textEditingController: textEditingController,
            chatController: chatController,
            notifier: notifier,
            room: room,
            context: context,
          );
        }
        // print("Media selected: ${event['paths']}");
      } else if (event['event'] == 'pickerHidden') {
        // print("Picker is hidden");
      } else if (event['event'] == 'pickerReopened') {
        // print("Picker is reopened");
      }
    });
    await _mediaPicker.sendEvent({
      "action": "showMediaPicker",
      "text": textEditingController!.text,
    });
    // await _mediaPicker.sendEvent({
    //   "action": "hideMediaPicker",
    // });
    // await _mediaPicker.sendEvent({
    //   "action": "reopenMediaPicker",
    // });
    // try {
    //   final Map<dynamic, dynamic> result = await platform
    //       .invokeMethod('showMediaPicker', {'inputString': inputString});
    //   // setState(() {
    //   selectedMediaPaths = List<String>.from(result['paths']);
    //   controllerString = result['controller'];
    //   method = result['method'];
    //   log(method,name: "method");

    //   // });
    // } on PlatformException catch (e) {
    //   // setState(() {
    //   // _selectedMediaPaths = "Failed to show media picker: '${e.message}'.";
    //   // });
    // }
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
