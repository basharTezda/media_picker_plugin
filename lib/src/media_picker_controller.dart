import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pro_image_editor/designs/zen_design/im_image_editor.dart'
    show ImImageEditor;

class TezdaIOSPicker {
  static const EventChannel _eventChannel = EventChannel('media_picker_events');
  static StreamSubscription? _eventSubscription;
  static MethodChannel methodChannel = MethodChannel('media_picker_channel');
  static Future<void> sendEvent(Map<String, dynamic> event) async {
    await methodChannel.invokeMethod('handleEvent', event);
  }

  static Stream<dynamic> onUpdateStream = _eventChannel
      .receiveBroadcastStream()
      .map((event) => event);
  void pickMedia({
    required bool onlyPhotos,
    required Function(Map<String, dynamic>) onMediaSelected,
    TextEditingController? textEditingController,
    required BuildContext context,
  }) async {
    bool isControllerNull = textEditingController == null;
    await sendEvent({
      "action": "showMediaPicker",
      "text": isControllerNull ? "" : textEditingController.text,
      "onlyPhotos": onlyPhotos,
    });
    _eventSubscription = onUpdateStream.listen((onData) async {
      if (onData['event'] == 'mediaSelected') {
        Future.delayed(Duration(seconds: 1), () {});
        List<String> pickedMedias = List<String>.from(onData['paths']);
        if (onData['method'] == 'edit') {
          if (!isControllerNull) {
            textEditingController.text = onData['controller'] ?? "";
          }
          final editedMedia = await openEditor(
            media: pickedMedias,
            textEditingController: textEditingController,
            // ignore: use_build_context_synchronously
            context: context,
          );
          if (editedMedia.isEmpty) {
            await sendEvent({
              "action": "reopenMediaPicker",
              "text": !isControllerNull ? textEditingController.text : "",
            });
            return;
          }
          _eventSubscription!.cancel();
          onMediaSelected.call({
            "media": editedMedia,
            "controller":
                textEditingController,
          });
          return;
        }
        if (onData['method'] == 'send') {
           if (!isControllerNull) {
            textEditingController.text = onData['controller'] ?? "";
          }
          _eventSubscription!.cancel();
          onMediaSelected.call({
            "media": pickedMedias,
            "controller":
                !isControllerNull
                    ? textEditingController
                    : TextEditingController(),
          });
          return;
        }
      }
    });
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
    return mediaAfterEditing;
  }
}
