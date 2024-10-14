import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AudioRecorderScreen(),
    );
  }
}

class AudioRecorderScreen extends StatefulWidget {
  const AudioRecorderScreen({super.key});

  @override
  AudioRecorderScreenState createState() => AudioRecorderScreenState();
}

class AudioRecorderScreenState extends State<AudioRecorderScreen> {
  static const _channel = MethodChannel('screenCaptureChannel');

  Future<void> _start() async {
    try {
      await _channel.invokeMethod('start');
    } on PlatformException catch (e) {
      print("Failed to start recording: ${e.message}");
    }
  }

  Future<void> _stop() async {
    try {
      await _channel.invokeMethod('stop');
    } on PlatformException catch (e) {
      print("Failed to stop recording: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('macOS System Audio Recorder'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _start,
              child: Text('Start Recording'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _stop,
              child: Text('Stop Recording'),
            ),
          ],
        ),
      ),
    );
  }
}
