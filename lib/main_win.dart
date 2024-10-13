import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:win32/win32.dart';

const sampleRate = 44100; // Sample rate
const channels = 2; // Number of channels (stereo)
const bytesPerSample = 4; // 32 bits (4 bytes)
const bufferSize = 44100 * 2; // Buffer for 2 seconds

/// Initialize COM
void initCOM() {
  check(CoInitializeEx(nullptr, COINIT.COINIT_APARTMENTTHREADED));
}

/// Check for errors
void check(int hr) {
  if (FAILED(hr)) throw WindowsException(hr);
}

/// Record audio from the microphone
void recordAudio() {
  // 1. Initialize COM
  try {
    initCOM();
  } catch (e) {
    print("COM initialization failed: $e");
    return;
  }

  // 2. Get audio device enumerator
  final pDeviceEnumerator = MMDeviceEnumerator.createInstance();
  final ppDevice = calloc<COMObject>();
  check(pDeviceEnumerator.getDefaultAudioEndpoint(0, 0, ppDevice.cast()));
  final pEndpoint = IMMDevice(ppDevice);

  // 3. Activate IAudioClient
  final ppAudioClient = calloc<COMObject>();
  final iidAudioClient = convertToIID(IID_IAudioClient);
  check(pEndpoint.activate(iidAudioClient, CLSCTX.CLSCTX_ALL, nullptr, ppAudioClient.cast()));
  free(iidAudioClient);
  final pAudioClient = IAudioClient(ppAudioClient);

  // 4. Get mix format
  final ppFormat = calloc<Pointer<WAVEFORMATEX>>();
  check(pAudioClient.getMixFormat(ppFormat));
  final pWaveFormat = ppFormat.value;

  // 5. Initialize audio stream
  check(pAudioClient.initialize(
      AUDCLNT_SHAREMODE.AUDCLNT_SHAREMODE_SHARED,
      0,
      10000000, // Buffer latency (10 ms)
      0,
      pWaveFormat,
      nullptr
  ));

  // 6. Get IAudioCaptureClient
  final ppCaptureClient = calloc<COMObject>();
  final iidAudioCaptureClient = convertToIID(IID_IAudioCaptureClient);
  check(pAudioClient.getService(iidAudioCaptureClient, ppCaptureClient.cast()));
  free(iidAudioCaptureClient);
  final pAudioCaptureClient = IAudioCaptureClient(ppCaptureClient);

  // 7. Start recording
  check(pAudioClient.start());

  // 8. Record data
  final audioBuffer = Uint8List(bufferSize * bytesPerSample);

  for (var i = 0; i < 10; i++) { // Record 10 packets
    // Get available data
    final pNumFramesAvailable = calloc<UINT32>(); // Use Pointer<UINT32>

    check(pAudioCaptureClient.getNextPacketSize(pNumFramesAvailable));
    int numFramesAvailable = pNumFramesAvailable.value; // Read value

    if (numFramesAvailable > 0) {
      // Allocate memory for buffer pointer
      Pointer<Pointer<BYTE>> pDataPointer = calloc<Pointer<BYTE>>();
      int numFramesToRead = 0; // Changed to int
      int flags = 0; // Changed to int

      // Get buffer
      check(pAudioCaptureClient.getBuffer(
          pDataPointer,
          calloc<UINT32>()..value = numFramesToRead, // Use calloc to allocate memory
          calloc<UINT32>()..value = flags, // Use calloc to allocate memory
          nullptr,
          nullptr
      ));

      // Get actual buffer pointer
      Pointer<BYTE> pData = pDataPointer.value;

      if (pData != nullptr) { // Check if pData is not null
        // Copy data to buffer
        final bytesRead = numFramesToRead * bytesPerSample;
        for (var j = 0; j < bytesRead; j++) {
          audioBuffer[j] = pData.elementAt(j).value;
        }

        // Release buffer
        check(pAudioCaptureClient.releaseBuffer(numFramesToRead));
      } else {
        print("Error: Buffer not initialized.");
      }

      calloc.free(pDataPointer); // Free memory allocated for data pointer
    }

    Sleep(100); // Wait for 100 ms before next read
    calloc.free(pNumFramesAvailable); // Free memory
  }

  // 9. Stop recording
  check(pAudioClient.stop());

  // 10. Free resources
  free(ppCaptureClient);
  free(ppFormat);
  free(ppDevice);

  print('Recording completed!');
}

void main() {
  runApp(const App());

}

class App extends StatelessWidget {
  const App({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('App')
        ),
        floatingActionButton: FloatingActionButton(onPressed: recordAudio),
      ),
    );
  }
}
