import 'package:flutter/material.dart';
import 'package:media_picker_plugin/media_picker_plugin.dart';

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: GestureDetector(
            onTap: () => picker.pickMedia(onlyPhotos: false, onMediaSelected: (media) {}),
            child: Text('Pick media'),
          ),
        ),
      ),
    );
  }
}
