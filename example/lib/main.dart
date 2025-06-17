import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_picker_plugin/media_picker_plugin.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey();
void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final picker = TezdaIOSPicker();

  @override
  void initState() {
    super.initState();
  }

  List<String> filePaths = [];
  List<String> thumbails = [];
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Column(
                    children: [
                      Text("Files: ${filePaths.length}"),
                      for (var filePath in filePaths)
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2,height:MediaQuery.of(context).size.height / 2 ,
                          child: Stack(
                            children: [
                              Image.file(
                                File(filePath),
                                errorBuilder: (context, error, stackTrace) {
                                  log("${filePath}");
                                  return VideoView(path: filePath);
                                },
                              ),
                              Text("${filePath}"),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Column(
                    children: [
                      Text("Thumbnails: ${thumbails.length}"),
                      for (var filePath in thumbails)
                        SizedBox(
                                                 width: MediaQuery.of(context).size.width / 2,height:MediaQuery.of(context).size.height / 2 ,
                          child: Stack(
                            children: [
                              Image.file(
                                File(filePath),
                                errorBuilder: (context, error, stackTrace) {
                                  return VideoView(path: filePath);
                                },
                              ),
                              Text("${filePath}"),
                            ],
                          ),
                        ),
                    ],
                  )
                ],
              ),
              Center(
                child: GestureDetector(
                  onTap: () => picker.pickMedia(
                    onlyPhotos: false,
                    textEditingController: TextEditingController(),
                    onMediaSelected: (media) async {
                      filePaths.clear();
                      filePaths = media['media'];
                      thumbails = media['thumbnails'];
                      // filePaths[0] = await _saveFile(
                      //                       filePaths[0],
                      //                     );
                      // log(filePaths[0].toString());
                      setState(() {});
                      // final dd = await TezdaIOSPicker.downloadVideoFromiCloud(
                      //     assetId: filePaths[0]);
                      // log(dd.toString());
                      // filePaths[0] = dd!;
                      // log(filePaths[0].toString());

                      // for (var i in filePaths) {
                      //
                      // }
                      // await TezdaIOSPicker.tryCompress(path: filePaths.first)
                      //     .then((compressedPath) {
                      //   filePaths[0] = compressedPath;
                      // });

                      setState(() {});
                    },
                    context: navigatorKey.currentContext!,
                  ),
                  child: Text('Pick media'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _saveFile(String filePath) async {
    final directory = await getApplicationDocumentsDirectory();

    final String videoFileName =
        'video_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final String destinationPath = path.join(directory.path, videoFileName);
    File(destinationPath).writeAsBytesSync(File(filePath).readAsBytesSync());
    return destinationPath;
  }
}

class VideoView extends StatefulWidget {
  const VideoView({required this.path});
//VideoView
  // final VideoViewType? viewType;
  final String path;

  @override
  _ButterFlyAssetVideoState createState() => _ButterFlyAssetVideoState();
}

class _ButterFlyAssetVideoState extends State<VideoView> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return GestureDetector(
      onTap: () {
        if (_controller.value.isPlaying) {
          _controller.pause();
        } else {
          _controller.play();
        }
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              VideoPlayer(_controller),
              // _ControlsOverlay(controller: _controller),
              VideoProgressIndicator(_controller, allowScrubbing: true),
            ],
          ),
        ),
      ),
    );
  }

  void _initVideoPlayer() async {
    String videoPath = widget.path;
    if (!File(videoPath).existsSync()) {
      log("File does not exist: ${widget.path}");
      videoPath = await TezdaIOSPicker.downloadVideoFromiCloud(
        widget.path,
      );
    }
    _controller = VideoPlayerController.file(
      File(videoPath),
      // viewType: widget.viewType!,
    );

    _controller.initialize().then((_) {
      setState(() {});
    });
  }
}
