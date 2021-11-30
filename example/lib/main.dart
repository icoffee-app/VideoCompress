import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:file_selector/file_selector.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  MediaInfo? info;

  File? _videoFile;
  File? _thumbnailFile;

  VideoPlayerController? _controller;

  _compressVideo() async {
    var file;
    if (Platform.isMacOS) {
      final typeGroup = XTypeGroup(label: 'videos', extensions: ['mov', 'mp4']);
      file = await openFile(acceptedTypeGroups: [typeGroup]);
    } else {
      final picker = ImagePicker();
      PickedFile? pickedFile = await picker.getVideo(
        source: ImageSource.camera,
        maxDuration: Duration(seconds: 10),
      );
      file = File(pickedFile!.path);
    }
    if (file == null) {
      return;
    }
    await VideoCompress.setLogLevel(0);
    info = await VideoCompress.compressVideo(
      file.path,
      quality: VideoQuality.MediumQuality,
      startTime: 0,
      duration: 10,
      deleteOrigin: false,
      includeAudio: true,
    );
    if (info == null) {
      return;
    }
    _thumbnailFile = await VideoCompress.getFileThumbnail(file.path);
    print('path: ${info!.path}, size: ${info!.filesize}');
    print(info.toString());
    _videoFile = info!.file;
    if (_videoFile == null) {
      return;
    }
    setState(() {});
    _controller = VideoPlayerController.file(_videoFile!)
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized,
        // even before the play button has been pressed.
        if (mounted) {
          setState(() {});
          _controller?.play();
        }
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 500,
              child: _controller != null && _controller!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    )
                  : _thumbnailFile != null
                      ? Image.file(_thumbnailFile!)
                      : const SizedBox(),
            ),
            const SizedBox(height: 20),
            if (info != null) ...[
              Text('path: ${info!.file}'),
              Text('size: ${info!.filesize}'),
              Text('width: ${info!.width}, height: ${info!.height}'),
              Text('duration: ${info!.duration}'),
            ]
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => _compressVideo(),
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
