import AVFoundation
import AppKit

class AudioCapture: NSObject {
    var captureSession: AVCaptureSession?
    var audioOutput: AVCaptureAudioDataOutput?
    var audioFileOutput: AVAudioFile?

    func startAudioCapture() {
        captureSession = AVCaptureSession()

        // Get the default audio input device
        guard let audioInput = AVCaptureDevice.default(for: .audio),
              let audioInputDevice = try? AVCaptureDeviceInput(device: audioInput) else {
            print("Failed to get audio input device.")
            return
        }

        captureSession?.addInput(audioInputDevice)

        audioOutput = AVCaptureAudioDataOutput()
        captureSession?.addOutput(audioOutput!)

        // Set the output file path
        let audioFilename = getDocumentsDirectory().appendingPathComponent("system_audio_recording.m4a")
        let fileURL = audioFilename
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        // Setup AVAudioFile for recording
        audioFileOutput = try? AVAudioFile(forWriting: fileURL, settings: settings)

        // Start capturing
        captureSession?.startRunning()
    }

    func stopAudioCapture() {
        captureSession?.stopRunning()
        audioFileOutput = nil
    }

    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
