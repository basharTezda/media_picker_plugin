import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TezdaIOSPicker {

  static const EventChannel _eventChannel = EventChannel(
    'media_picker_events',
  );

  Stream<dynamic> get mediaPickerEvents =>
      _eventChannel.receiveBroadcastStream();

  static MethodChannel methodChannel = MethodChannel('media_picker_channel');

  static Future<void> sendEvent(Map<String, dynamic> event) async {
    await methodChannel.invokeMethod('handleEvent', event);
  }

  static Stream<dynamic> onUpdateStream = _eventChannel
      .receiveBroadcastStream()
      .map((event) => event);
  void pickMedia({
    required bool onlyPhotos ,
    required Function(List<String>) onMediaSelected,
    TextEditingController? textEditingController,
    context,
  }) async {
   
    await sendEvent({
      "action": "showMediaPicker",
      "text": textEditingController != null ? textEditingController.text : "",
      "onlyPhotos": onlyPhotos
    });
    onUpdateStream.listen((onData) {
      if(onData['mediaSelected']!=null){
        onMediaSelected.call(onData['mediaSelected']);
        log(onData.toString());
        return;
      }
      log(onData.toString());
    });
    // _eventSubscription = _mediaPicker.mediaPickerEvents.listen((event) {
    //   if (event['event'] == 'mediaSelected') {
    //     List<String> selectedMediaPaths = List<String>.from(event['paths']);
    //     String controllerString = event['controller'];
    //     String method = event['method'];
    //     textEditingController!.text = controllerString;
    //     if (method == "send") {
    //       // state = state.copyWith(
    //       //   mediaFileSelected: true,
    //       //   displayFile: selectedMediaPaths.map((toElement) {
    //       //     return File(toElement);
    //       //   }).toList(),
    //       //   // chosenFile: File(selectedMediaPaths.first),
    //       //   // isVideoFile: true,
    //       // );
    //       // sendMediaFile(
    //       //     user: user,
    //       //     textEditingController: textEditingController,
    //       //     chatController: chatController,
    //       //     room: room,
    //       //     notifier: notifier,
    //       //     context: context);
    //       textEditingController.clear();
    //     } else {
    //       // _openEditor(
    //       //   images: selectedMediaPaths,
    //       //   user: user,
    //       //   textEditingController: textEditingController,
    //       //   chatController: chatController,
    //       //   notifier: notifier,
    //       //   room: room,
    //       //   context: context,
    //       // );
    //     }
    //     // print("Media selected: ${event['paths']}");
    //   } else if (event['event'] == 'pickerHidden') {
    //     // print("Picker is hidden");
    //   } else if (event['event'] == 'pickerReopened') {
    //     // print("Picker is reopened");
    //   }
    // });

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
