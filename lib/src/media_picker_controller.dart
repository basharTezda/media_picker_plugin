import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pro_image_editor/designs/zen_design/im_image_editor.dart'
    show ImImageEditor;

class TezdaIOSPicker {
  static const EventChannel _eventChannel = EventChannel('media_picker_events');
  static StreamSubscription? _eventSubscription;
  static MethodChannel methodChannel = MethodChannel('media_picker_channel');
  static Future<dynamic> sendEvent(
      {required Map<String, dynamic> event,
      String method = 'handleEvent'}) async {
    return await methodChannel.invokeMethod(method, event);
  }
  static Future<String> downloadVideoFromiCloud(String assetId) async {
    try {
      final String filePath = await methodChannel.invokeMethod(
        'downloadVideoFromiCloud',
        {'assetId': assetId},
      );
      return filePath;
    } on PlatformException catch (e) {
      throw Exception('Failed to download video: ${e.message}');
    }
  }
  static Future<void> dispose() async {
    if (_eventSubscription != null) {
      await _eventSubscription!.cancel();
      _eventSubscription = null;
    }
  }

static Future<String> tryCompress({required String path}) async {
  try {
    // Get original file size in MB
    final originalFile = File(path);
    final originalSizeBytes = await originalFile.length();
    final originalSizeMB = originalSizeBytes / (1024 * 1024);
    developer.log('Original file size: ${originalSizeMB.toStringAsFixed(2)} MB');

    // Compress the file
    final result = await methodChannel.invokeMethod('tryCompress', {'videoPath': path});
    
    // Get compressed file size in MB
    final compressedFile = File(result);
    final compressedSizeBytes = await compressedFile.length();
    final compressedSizeMB = compressedSizeBytes / (1024 * 1024);
    developer.log('Compressed file size: ${compressedSizeMB.toStringAsFixed(2)} MB');
    
    // Calculate compression ratio (percentage saved)
    final ratio = (originalSizeBytes - compressedSizeBytes) / originalSizeBytes * 100;
    developer.log('Compression saved: ${ratio.toStringAsFixed(2)}%');
    
    return result;
  } catch (e) {
    developer.log('Error compressing file: $e');
    return path;
  }
}

  static final Stream<dynamic> _onUpdateStream =
      _eventChannel.receiveBroadcastStream().map((event) => event);
  void pickMedia({
    required bool onlyPhotos,
    required Function(Map<String, dynamic>) onMediaSelected,
    TextEditingController? textEditingController,
    required BuildContext context,
  }) async {
    bool isControllerNull = textEditingController == null;
    await sendEvent(event: {
      "action": "showMediaPicker",
      "text": isControllerNull ? "" : textEditingController.text,
      "onlyPhotos": onlyPhotos,
    });
    _eventSubscription = _onUpdateStream.listen((onData) async {
      if (onData['event'] == 'mediaSelected') {
        Future.delayed(Duration(seconds: 1), () {});
        List<String> pickedMedias = List<String>.from(onData['paths']);
           List<String> thumbnails = List<String>.from(onData['thumbnails']);
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
            await sendEvent(event: {
              "action": "reopenMediaPicker",
              "text": !isControllerNull ? textEditingController.text : "",
            });
            return;
          }
          _eventSubscription!.cancel();
          onMediaSelected.call({
            "media": editedMedia,
            "controller": textEditingController,
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
             "thumbnails": thumbnails,
            "controller": !isControllerNull
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
            (c, n, _) => Scaffold(
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
