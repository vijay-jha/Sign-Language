import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.cameras,
  });

  final List<CameraDescription> cameras;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late CameraDescription currentCamera;
  bool isFront = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    currentCamera = widget.cameras[0];
    _controller = CameraController(
      currentCamera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggleCamera() {
    setState(() {
      currentCamera = isFront ? widget.cameras[0] : widget.cameras[1];
      _controller = CameraController(
        currentCamera,
        ResolutionPreset.medium,
      );
      _initializeControllerFuture = _controller.initialize();
      isFront = !isFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Take a picture')),
        body: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return CameraPreview(_controller);
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingActionButton(
              onPressed: () async {
                try {
                  await _initializeControllerFuture;
                  toggleCamera();
                } catch (e) {}
              },
              child: const Icon(Icons.flip_camera_android_sharp),
            ),
            FloatingActionButton(
              onPressed: () async {
                try {
                  await _initializeControllerFuture;
                  _recordVideo();
                } catch (e) {}
              },
              child: const Icon(Icons.circle_outlined),
            ),
          ],
        ));
  }

  void _recordVideo() {
    Timer.periodic(
        const Duration(seconds: 1),
        (_) => () async {
              if (_isRecording) {
                final file = await _controller.stopVideoRecording();
                setState(() => _isRecording = false);
                final route = MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => VideoPage(filePath: file.path),
                );
                Navigator.push(context, route);
              } else {
                await _controller.prepareForVideoRecording();
                await _controller.startVideoRecording();
                setState(() => _isRecording = true);
              }
            });
  }

  // void trimVideo() {}
}

class VideoPage extends StatefulWidget {
  final String filePath;

  const VideoPage({Key? key, required this.filePath}) : super(key: key);

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late VideoPlayerController _videoPlayerController;

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  Future _initVideoPlayer() async {
    _videoPlayerController = VideoPlayerController.file(File(widget.filePath));
    await _videoPlayerController.initialize();
    await _videoPlayerController.setLooping(true);
    await _videoPlayerController.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        elevation: 0,
        backgroundColor: Colors.black26,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {},
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: FutureBuilder(
        future: _initVideoPlayer(),
        builder: (context, state) {
          if (state.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return VideoPlayer(_videoPlayerController);
          }
        },
      ),
    );
  }
}
