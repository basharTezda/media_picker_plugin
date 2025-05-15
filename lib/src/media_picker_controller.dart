import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pro_image_editor/designs/zen_design/im_image_editor.dart'
    show ImImageEditor;

class TezdaIOSPicker {
  static const EventChannel _eventChannel = EventChannel('media_picker_events');
  static StreamSubscription? _eventSubscription;
  // Stream<dynamic> get mediaPickerEvents =>
  //     _eventChannel.receiveBroadcastStream();

  static MethodChannel methodChannel = MethodChannel('media_picker_channel');

  static Future<void> sendEvent(Map<String, dynamic> event) async {
    await methodChannel.invokeMethod('handleEvent', event);
  }

  static Stream<dynamic> onUpdateStream = _eventChannel
      .receiveBroadcastStream()
      .map((event) => event);
  void pickMedia({
    required bool onlyPhotos,
    required Function(List<String>) onMediaSelected,
    TextEditingController? textEditingController,
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    await sendEvent({
      "action": "showMediaPicker",
      "text": textEditingController != null ? textEditingController.text : "",
      "onlyPhotos": onlyPhotos,
    });
    _eventSubscription = onUpdateStream.listen((onData) async {
      if (onData['event'] == 'mediaSelected') {
        Future.delayed(Duration(seconds: 1), () {});
        List<String> pickedMedias = List<String>.from(onData['paths']);
        if (onData['method'] == 'edit') {
          debugPrint(
            'Context valid: ${navigatorKey.currentContext?.findAncestorWidgetOfExactType<MaterialApp>() != null}',
          );

          final editedMedia = await openEditor(
            media: pickedMedias,
            textEditingController: textEditingController,
            context: navigatorKey.currentContext!,
          );
          if (editedMedia.isEmpty) {
            await sendEvent({
              "action": "reopenMediaPicker",
              "text":
                  textEditingController != null
                      ? textEditingController.text
                      : "",
            });
            return;
          }
          _eventSubscription!.cancel();
          onMediaSelected.call(editedMedia);
          return;
        }
        if (onData['method'] == 'send') {
          _eventSubscription!.cancel();
          onMediaSelected.call(pickedMedias);
          return;
        }
      }

      log("${onData}");
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

  static Future<List<String>> openEditor({
    required List<String> media,
    required TextEditingController? textEditingController,
    required BuildContext context,
  }) async {
    List<String> mediaAfterEditing = [];
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (_, _, _) => Scaffold(
              backgroundColor: const Color.fromRGBO(0, 0, 0, 1),
              body: ImImageEditor(
                textEditingText: 'Message',
                doneText: "Done",
                onDone: (List<String> editedImages) {
                  if (editedImages.isNotEmpty) {
                    mediaAfterEditing = editedImages;
                    if (textEditingController != null) {
                      textEditingController.clear();
                    }
                  }
                },
                images: media,
                textEditingController:
                    textEditingController ?? TextEditingController(),
              ),
            ),
      ),
    );
    // .then((value) async {
    //   return mediaAfterEditing;
    //   // await _mediaPicker.sendEvent({
    //   //   "action": "reopenMediaPicker",
    //   //   "text": textEditingController!.text,
    //   // });

    //   // await _mediaPicker.sendEvent({
    //   //   "action": "showMediaPicker",
    //   //   "text": textEditingController!.text,
    //   // });
    //   // await const MethodChannel('mediapicker').invokeMethod("reopenMediaPicker");
    // });
    return mediaAfterEditing;
  }
}
